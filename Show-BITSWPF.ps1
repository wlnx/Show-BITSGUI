#Requires -Version 3

<#
    .EXTERNALHELP .\l10n\help.xml
#>

[CmdletBinding(
    PositionalBinding=$true
)]
param(
    [Alias('Lang')]
    [string]$UICulture = (Get-UICulture).Name
)

#Либо MTA, либо Open/SaveFileDialog... =(
if ([threading.thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    Start-Process powershell.exe -ArgumentList ("-sta " + $MyInvocation.MyCommand.Definition);
    Exit;
}
#Чит, однако

Add-Type –assemblyName PresentationFramework;
Add-Type –assemblyName PresentationCore;
Add-Type –assemblyName WindowsBase;

Import-LocalizedData -UICulture $UICulture -BaseDirectory '.\l10n' -FileName 'vars.psd1' -BindingVariable Strings;

[xml]$XAMLMainWnd = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006">
    <Grid x:Name="MainGrid">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Menu Grid.Row="0">
            <MenuItem x:Name="miFile">
                <MenuItem x:Name="miCreateTransfer"/>
                <Separator/>
                <MenuItem x:Name="miExit"/>
            </MenuItem>
            <MenuItem x:Name="miEdit">
                <MenuItem x:Name="miSuspend" IsEnabled="False"/>
                <MenuItem x:Name="miResume" IsEnabled="False"/>
                <MenuItem x:Name="miStop" IsEnabled="False"/>
            </MenuItem>
        </Menu>
        <ListView Grid.Row="1" Height="Auto">
            <ListView.View>
                <GridView>
                    <GridViewColumn x:Name="gvcId" Width="Auto"/>
                    <GridViewColumn x:Name="gvcCaption" Width="Auto"/>
                    <GridViewColumn x:Name="gvcSource" Width="Auto"/>
                    <GridViewColumn x:Name="gvcDestination" Width="Auto"/>
                    <GridViewColumn x:Name="gvcSent" Width="Auto"/>
                    <GridViewColumn x:Name="gvcSize" Width="Auto"/>
                    <GridViewColumn x:Name="gvcState" Width="Auto"/>
                </GridView>
            </ListView.View>
        </ListView>
    </Grid>
</Window>
"@;

[xml]$XAMLBrowseWnd = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="100"/>
            <ColumnDefinition Width="200"/>
            <ColumnDefinition Width="100"/>
        </Grid.ColumnDefinitions>
        <Label x:Name="lbSrc" Grid.Row="0" Grid.Column="0"/>
        <Label x:Name="lbDst" Grid.Row="1" Grid.Column="0"/>
        <TextBox x:Name="tbSrc" Grid.Column="1" Grid.Row="0"/>
        <TextBox x:Name="tbDst" Grid.Column="1" Grid.Row="1"/>
        <Button x:Name="btSrcBrowse" Grid.Row="0" Grid.Column="2" Margin="2" Width="90"/>
        <Button x:Name="btDstBrowse" Grid.Row="1" Grid.Column="2" Margin="2" Width="90"/>
        <Button x:Name="btOk" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Margin="2" Width="90" IsDefault="True"/>
        <Button x:Name="btCancel" Grid.Row="2" Grid.Column="2" Margin="2" Width="90" IsCancel="True"/>
    </Grid>
</Window>

"@;

$MainWnd = [System.Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $XAMLMainWnd));

$MainWnd.Title = $Strings.'MainWnd.Text';

[string]$MainWnd.FindName('miFile').Header = $Strings.'miFile';
[string]$MainWnd.FindName('miCreateTransfer').Header = $Strings.'miCreateTransfer';
[string]$MainWnd.FindName('miExit').Header = $Strings.'miExit';

[string]$MainWnd.FindName('miEdit').Header = $Strings.'miEdit';
[string]$MainWnd.FindName('miSuspend').Header = $Strings.'miSuspend';
[string]$MainWnd.FindName('miResume').Header = $Strings.'miResume';
[string]$MainWnd.FindName('miStop').Header = $Strings.'miStop';

[string]$MainWnd.FindName('gvcId').Header = $Strings.'MainTable.Columns.Id';
[string]$MainWnd.FindName('gvcCaption').Header = $Strings.'MainTable.Columns.Caption';
[string]$MainWnd.FindName('gvcSource').Header = $Strings.'MainTable.Columns.Source';
[string]$MainWnd.FindName('gvcDestination').Header = $Strings.'MainTable.Columns.Destination';
[string]$MainWnd.FindName('gvcSent').Header = $Strings.'MainTable.Columns.Sent';
[string]$MainWnd.FindName('gvcSize').Header = $Strings.'MainTable.Columns.Size';
[string]$MainWnd.FindName('gvcState').Header = $Strings.'MainTable.Columns.State';

[string]$MainWnd.FindName('miCreateTransfer').AddHandler(
    [System.Windows.Controls.MenuItem]::ClickEvent,
    [System.Windows.RoutedEventHandler]{
        $BrowseWnd = [System.Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $XAMLBrowseWnd));
        $BrowseWnd.Title = $Strings.'fmSrcDst.Text';
        [string]$BrowseWnd.FindName('lbSrc').Content = $Strings.'lbSrc.Text';
        [string]$BrowseWnd.FindName('lbDst').Content = $Strings.'lbDst.Text';
        [string]$BrowseWnd.FindName('btSrcBrowse').Content = $Strings.'btSrcBrowse.Text';
        [string]$BrowseWnd.FindName('btDstBrowse').Content = $Strings.'btDstBrowse.Text';
        [string]$BrowseWnd.FindName('btOk').Content = $Strings.'btOk.Text';
        [string]$BrowseWnd.FindName('btCancel').Content = $Strings.'btCancel.Text';
        
        $BrowseWnd.FindName('tbSrc').AddHandler(
            [System.Windows.Controls.TextBox]::TextChangedEvent,
            [System.Windows.Controls.TextChangedEventHandler]{
                # ToDo: ОЧЕНЬ глючный эвент хэндлер, заполняет btDst какой-то хернёй
                if ($BrowseWnd.FindName('tbDst').Text -eq '') {
                    $DelimPos = $BrowseWnd.FindName('tbSrc').Text.LastIndexOf('/');
                    if ($DelimPos -eq -1) {$DelimPos = $BrowseWnd.FindName('tbSrc').Text.LastIndexOf('\');}
                    if ($DelimPos -eq -1) {$BrowseWnd.FindName('tbDst').Text = $BrowseWnd.FindName('tbSrc').Text} else {$BrowseWnd.FindName('tbDst').Text = Join-Path -Path((Get-Item .).FullName) -ChildPath $BrowseWnd.FindName('tbSrc').Text.Remove(0, $DelimPos + 1)}
                }
            }
        );
        
        $BrowseWnd.ShowDialog();
        Remove-Variable -Name 'BrowseWnd';
    }
);

$null = $MainWnd.ShowDialog();
Remove-Variable -Name 'MainWnd';