# MapChanger
![GitHub release (latest by date)](https://img.shields.io/github/v/release/syyePhenomenol/MapChanger)
![Downloads GitHub all releases](https://img.shields.io/github/downloads/syyePhenomenol/MapChanger/total)

MapChanger is a Hollow Knight API for modifying the existing map behaviour.

## Unity 6 compatibility patch

这个仓库基于 syyePhenomenol 的 [MapChanger 1.3.11](https://github.com/syyePhenomenol/MapChanger/releases/tag/v1.3.11)，目标为 Windows Steam 版《空洞骑士》`1.5.12620` 和 [Modding API v78](https://github.com/hk-modding/api/pull/164)。

- 地图图标、边框和背景使用 `Inventory` 绘制层，顺序设为 `1`，让图标画在排序值为 `0` 的地图底图上方。
- 区域名称、通路标签和快捷地图标题改用新版地图预制件实际挂载的 `TMProOld.TextMeshPro`，让 MapChanger 能读取现有的本地化文字组件。

### 安装与回退

1. 退出游戏，备份 `hollow_knight_Data/Managed/Mods/MapChanger` 内现有的 `MapChanger.dll` 和 `MapChanger.pdb`。
2. 从 [Releases](../../releases) 下载兼容补丁，解压后把同名的两个文件放到该目录。
3. 启动游戏。Vanilla Map Mod 会继续使用该目录下的 MapChanger。

需要回退时，退出游戏并换回第一步的两个备份文件。

### 复现发布包的补丁

仓库包含对应 C# 源码和许可证。发布包由 PowerShell 脚本在原版 `MapChanger.dll` 上应用同样的两项修改生成。请使用原版 1.3.11 发布包中的 DLL 和 PDB 作为输入，并指定安装了 v78 的 `Managed` 目录。

```powershell
pwsh -File ./tools/Patch-MapChanger.ps1 -ManagedDirectory '<游戏目录>/hollow_knight_Data/Managed' -InputDll '<原版包目录>/MapChanger.dll' -OutputDll './out/MapChanger.dll'
```

# Dependencies:
- [MagicUI](https://github.com/BadMagic100/HollowKnight.MagicUI)
- [Satchel](https://github.com/PrashantMohta/Satchel)
- [Vasi](https://github.com/fifty-six/HollowKnight.Vasi)

# Optional and compatible:
- [AdditionalMaps](https://github.com/SFGrenade/AdditionalMaps)
- [DebugMod](https://github.com/TheMulhima/HollowKnight.DebugMod)


Please make sure all of the dependent mods are installed and up to date.

# For developers
- To be added
