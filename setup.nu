let default_mod = "MyModName"; let default_author = "Cratior"; let default_desc = "SFS mod with auto-generated structure"; let default_ns = "MyMod"; let default_year = (date now | format date "%Y"); let mod_in = (input ("Project name (default: " + $default_mod + "): ")); let mod = (if $mod_in == "" { $default_mod } else { $mod_in }); let author_in = (input ("Author (default: " + $default_author + "): ")); let author = (if $author_in == "" { $default_author } else { $author_in }); let desc_in = (input ("Description (default: " + $default_desc + "): ")); let desc = (if $desc_in == "" { $default_desc } else { $desc_in }); let ns_in = (input ("Namespace (default: " + $default_ns + "): ")); let ns = (if $ns_in == "" { $default_ns } else { $ns_in }); let year_in = (input ("Year (default: " + $default_year + "): ")); let year = (if $year_in == "" { $default_year } else { $year_in }); let steam_root = (try { (^reg query 'HKCU\Software\Valve\Steam' /v SteamPath | lines | find 'SteamPath' | first | parse -r 'SteamPath\s+REG_SZ\s+(?<path>.+)' | get path.0 | str trim) } catch { try { (^reg query 'HKLM\SOFTWARE\WOW6432Node\Valve\Steam' /v InstallPath | lines | find 'InstallPath' | first | parse -r 'InstallPath\s+REG_SZ\s+(?<path>.+)' | get path.0 | str trim) } catch { "" } }); let sfs_path = (if $steam_root != "" { $steam_root + '\steamapps\common\Spaceflight Simulator\Spaceflight Simulator Game\Mods' } else { 'C:\Program Files (x86)\Steam\steamapps\common\Spaceflight Simulator\Spaceflight Simulator Game\Mods' }); print ("Detected Mods folder: " + $sfs_path); let confirm = (input "Continue? (y/n): "); if $confirm != "y" { error make {msg: "Cancelled"} }; ^dotnet new sln -n $mod; ^dotnet new classlib -n $mod -o $mod; cp -r $"($env.USERPROFILE)/Documents/GitHub/SFS-UI-wrapped/dependacies" $"($mod)/dependacies"; let csproj = $"($mod)/($mod).csproj"; open $csproj | str replace '</Project>' (
'  <PropertyGroup>
    <TargetFramework>netstandard2.1</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>false</ImplicitUsings>

    <!-- Performance (safe for Unity + Debug) -->
    <Optimize>true</Optimize>
    <Deterministic>true</Deterministic>
    <CheckForOverflowUnderflow>false</CheckForOverflowUnderflow>

    <!-- Debug but fast -->
    <DebugType>portable</DebugType>
    <DebugSymbols>true</DebugSymbols>

    <!-- JIT optimizations -->
    <TieredCompilation>true</TieredCompilation>
    <TieredCompilationQuickJit>true</TieredCompilationQuickJit>
    <TieredCompilationQuickJitForLoops>true</TieredCompilationQuickJitForLoops>

    <!-- Reduce runtime overhead -->
    <InvariantGlobalization>true</InvariantGlobalization>
    <UseSystemResourceKeys>true</UseSystemResourceKeys>
</PropertyGroup>

<ItemGroup>
    <Reference Include="0Harmony"><HintPath>dependacies\0Harmony.dll</HintPath></Reference>
    <Reference Include="Assembly-CSharp"><HintPath>dependacies\Assembly-CSharp.dll</HintPath></Reference>
    <Reference Include="Newtonsoft.Json"><HintPath>dependacies\Newtonsoft.Json.dll</HintPath></Reference>
    <Reference Include="UITools"><HintPath>dependacies\UITools.dll</HintPath></Reference>
    <Reference Include="UnityEngine"><HintPath>dependacies\UnityEngine.dll</HintPath></Reference>
    <Reference Include="UnityEngine.CoreModule"><HintPath>dependacies\UnityEngine.CoreModule.dll</HintPath></Reference>
    <Reference Include="UnityEngine.ImageConversionModule"><HintPath>dependacies\UnityEngine.ImageConversionModule.dll</HintPath></Reference>
    <Reference Include="UnityEngine.IMGUIModule"><HintPath>dependacies\UnityEngine.IMGUIModule.dll</HintPath></Reference>
    <Reference Include="UnityEngine.InputLegacyModule"><HintPath>dependacies\UnityEngine.InputLegacyModule.dll</HintPath></Reference>
    <Reference Include="UnityEngine.TextRenderingModule"><HintPath>dependacies\UnityEngine.TextRenderingModule.dll</HintPath></Reference>
    <Reference Include="UnityEngine.UI"><HintPath>dependacies\UnityEngine.UI.dll</HintPath></Reference>
    <Reference Include="UnityEngine.UIModule"><HintPath>dependacies\UnityEngine.UIModule.dll</HintPath></Reference>
</ItemGroup>

<Target Name="CopyModToSFS" AfterTargets="Build">
    <PropertyGroup>
      <SFSModsPath>' + $sfs_path + '</SFSModsPath>
    </PropertyGroup>

    <Message Text="Copying mod to $(SFSModsPath)" Importance="high" />

    <Copy 
        SourceFiles="' + '$(OutputPath)' + '$(AssemblyName).dll"
        DestinationFolder="' + '$(SFSModsPath)' + '" 
        SkipUnchangedFiles="true" />
</Target>
</Project>'
) | save --force $csproj; let main_cs = ('using System.Collections.Generic;
using ModLoader;

namespace ' + $ns + '
{
    public class Main : Mod
    {
        public override string ModNameID => "' + $mod + '";
        public override string DisplayName => "' + $mod + '";
        public override string Author => "' + $author + '";
        public override string MinimumGameVersionNecessary => "1.5.10";
        public override string ModVersion => "0.0.1";
        public override string Description => "' + $desc + '";

        public override Dictionary<string, string> Dependencies => new Dictionary<string, string>
        {
            { "UITools", "1.1.5" }
        };

        public override void Early_Load()
        {
            base.Early_Load();
            
        }

        public override void Load()
        {
            base.Load();


        }
    }
}'); $main_cs | save --force $"($mod)/Main.cs"; rm -f $"($mod)/Class1.cs"; ^dotnet sln $"($mod).sln" add $csproj; ^dotnet build $csproj -c Debug; print ("Build configured: DLL will auto-copy on msbuild")
