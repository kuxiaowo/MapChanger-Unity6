#requires -Version 7.0
param(
    [Parameter(Mandatory)] [string]$ManagedDirectory,
    [Parameter(Mandatory)] [string]$InputDll,
    [Parameter(Mandatory)] [string]$OutputDll
)

$ErrorActionPreference = 'Stop'
$managed = (Resolve-Path -LiteralPath $ManagedDirectory).ProviderPath
$inputPath = (Resolve-Path -LiteralPath $InputDll).ProviderPath
$outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDll)
if ($inputPath -eq $outputPath) { throw 'Choose a separate output path.' }
if ([IO.Path]::GetFileName($outputPath) -ne 'MapChanger.dll') { throw 'Name the output MapChanger.dll.' }
if (-not [IO.File]::Exists([IO.Path]::ChangeExtension($inputPath, '.pdb'))) {
    throw 'Put the upstream MapChanger.pdb next to the input DLL.'
}
$expected = '80A105ABC2055CD1FAF0CB0DF2914D11B30DAE5DE45B04A291DA398166D6AD41'
if ((Get-FileHash -LiteralPath $inputPath).Hash -ne $expected) { throw 'Expected the upstream MapChanger 1.3.11 DLL.' }

Add-Type -Path (Join-Path $managed 'Mono.Cecil.dll')
$resolver = [Mono.Cecil.DefaultAssemblyResolver]::new()
$resolver.AddSearchDirectory($managed)
$reader = [Mono.Cecil.ReaderParameters]::new()
$reader.AssemblyResolver = $resolver
$reader.ReadSymbols = $true
$mapChanger = [Mono.Cecil.ModuleDefinition]::ReadModule($inputPath, $reader)
$game = [Mono.Cecil.ModuleDefinition]::ReadModule((Join-Path $managed 'Assembly-CSharp.dll'))
$unity = [Mono.Cecil.ModuleDefinition]::ReadModule((Join-Path $managed 'UnityEngine.CoreModule.dll'))
$assemblyStream = [IO.MemoryStream]::new()
$symbolStream = [IO.MemoryStream]::new()

try {
    $text = $game.GetType('TMProOld.TextMeshPro')
    $obsolete = @($mapChanger.GetTypeReferences() | Where-Object {
        $_.FullName -eq 'TMPro.TextMeshPro' -and $_.Scope.Name -eq $game.Assembly.Name.Name
    })
    if ($null -eq $text -or $obsolete.Count -ne 1) { throw 'Expected the Unity 6 map text component and its legacy reference.' }
    $obsolete[0].Namespace = $text.Namespace

    $orderSetter = $unity.GetType('UnityEngine.Renderer').Methods | Where-Object Name -eq 'set_sortingOrder'
    $orderSetter = $mapChanger.ImportReference($orderSetter)
    foreach ($name in @('Pin', 'BorderedPin', 'BorderedBackgroundPin')) {
        $type = $mapChanger.GetType('MapChanger.MonoBehaviours.' + $name)
        $initialize = $type.Methods | Where-Object Name -eq 'Initialize'
        $setLayer = $initialize.Body.Instructions | Where-Object {
            $_.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Callvirt -and $_.Operand.Name -eq 'set_sortingLayerName'
        }
        if (@($setLayer).Count -ne 1 -or $setLayer.Previous.Operand -ne 'HUD') {
            throw "Unexpected renderer initialization in $name."
        }
        $setLayer.Previous.Operand = 'Inventory'
        $il = $initialize.Body.GetILProcessor()
        $il.InsertBefore($setLayer.Previous, $il.Create([Mono.Cecil.Cil.OpCodes]::Dup))
        $order = $il.Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_1)
        $il.InsertAfter($setLayer, $order)
        $il.InsertAfter($order, $il.Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $orderSetter))
    }

    $writer = [Mono.Cecil.WriterParameters]::new()
    $writer.WriteSymbols = $true
    $writer.SymbolWriterProvider = [Mono.Cecil.Cil.PortablePdbWriterProvider]::new()
    $writer.SymbolStream = $symbolStream
    $mapChanger.Write($assemblyStream, $writer)

    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputPath)) | Out-Null
    [IO.File]::WriteAllBytes($outputPath, $assemblyStream.ToArray())
    [IO.File]::WriteAllBytes([IO.Path]::ChangeExtension($outputPath, '.pdb'), $symbolStream.ToArray())
} finally {
    $symbolStream.Dispose()
    $assemblyStream.Dispose()
    $unity.Dispose()
    $game.Dispose()
    $mapChanger.Dispose()
    $resolver.Dispose()
}
