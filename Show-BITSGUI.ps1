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

Import-LocalizedData -UICulture $UICulture -BaseDirectory '.\l10n' -FileName 'vars.psd1' -BindingVariable Strings;

#[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms");
Add-Type -AssemblyName System.Windows.Forms;

#Либо MTA, либо Open/SaveFileDialog... =(
if ([threading.thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    Start-Process powershell.exe -ArgumentList ("-sta " + $MyInvocation.MyCommand.Definition);
    Exit;
}
#Чит, однако

Import-Module BitsTransfer;

#Константы
$BITSID = 0;
$BITSName = 1;
$BITSSrc = 2;
$BITSDst = 3;
$BITSTransferred = 4;
$BITSSize = 5;
$BITSState = 6;
#Кончились

#Инициализация главного окна
$MainWnd = New-Object System.Windows.Forms.Form;
$MainWnd.Text = $Strings.'MainWnd.Text';
[System.Windows.Forms.ListView]$MainTable | Out-Null;
[System.Windows.Forms.MenuStrip]$mm | Out-Null;

#Инициализация главного меню
$miTmp = New-Object System.Windows.Forms.ToolStripMenuItem($Strings.'miCreateTransfer', $null,
    {
        $fmSrcDst = New-Object System.Windows.Forms.Form;
        $fmSrcDst.Text = $Strings.'fmSrcDst.Text';
        
        $tSrc = New-Object System.Windows.Forms.TextBox;
        $tSrc.Left = 25;
        $tSrc.Top = 25;
		$tSrc.Add_TextChanged({
				if ($tDst.Text -eq '') {
					$DelimPos = $tSrc.Text.LastIndexOf('/');
					if ($DelimPos -eq -1) {$DelimPos = $tSrc.Text.LastIndexOf('\');}
					if ($DelimPos -eq -1) {$tDst.Text = $tSrc.Text} else {$tDst.Text = Join-Path -Path((Get-Item .).FullName) -ChildPath $tSrc.Text.Remove(0, $DelimPos + 1)}
				}
			});
        $fmSrcDst.Controls.Add($tSrc);
		
		$lbSrc = New-Object System.Windows.Forms.Label;
		$lbSrc.Text = $Strings.'lbSrc.Text';
		$lbSrc.Left = $tSrc.Left;
		$lbSrc.Top = $tSrc.Top - $lbSrc.Height;
		$fmSrcDst.Controls.Add($lbSrc);
        
        $btSrcBrowse = New-Object System.Windows.Forms.Button;
        $btSrcBrowse.Text = $Strings.'btSrcBrowse.Text';
        $btSrcBrowse.Top = $tSrc.Top;
        $btSrcBrowse.Left = $tSrc.Left + $tSrc.Width + 25;
        $btSrcBrowse.Add_Click({
            $od = New-Object System.Windows.Forms.OpenFileDialog;
            $od.Title = $Strings.'od.Title';
            $od.Multiselect = $false;
            $od.CheckFileExists = $true;
            $od.initialDirectory = (Get-Item .).FullName;
            $od.filter = $Strings.'od.filter.AllFiles' + " (*.*)| *.*";
            #$od.ShowHelp = $true;
            if ($od.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {$tSrc.Text = $od.FileName};
            $od.Dispose();
        });
        $fmSrcDst.Controls.Add($btSrcBrowse);
        
        $tDst = New-Object System.Windows.Forms.TextBox;
        $tDst.Left = 25;
        $tDst.Top = 2*25 + $tSrc.Height;
        $fmSrcDst.Controls.Add($tDst);
		
		$lbDst = New-Object System.Windows.Forms.Label;
		$lbDst.Text = $Strings.'lbDst.Text';
		$lbDst.Left = $tDst.Left;
		$lbDst.Top = $tDst.Top - $lbDst.Height;
		$fmSrcDst.Controls.Add($lbDst);
        
        $btDstBrowse = New-Object System.Windows.Forms.Button;
        $btDstBrowse.Text = $Strings.'btDstBrowse.Text';
        $btDstBrowse.Top = $tDst.Top;
        $btDstBrowse.Left = $tSrc.Left + $tSrc.Width + 25;
        $btDstBrowse.Add_Click({
            $sd = New-Object System.Windows.Forms.SaveFileDialog;
            $sd.Title = $Strings.'sd.Title';
            $sd.CheckPathExists = $true;
            $sd.CheckFileExists = $false;
            $sd.initialDirectory = (Get-Item .).FullName;
            $sd.filter = $Strings.'sd.filter.AllFiles' + " (*.*)| *.*";
            #$sd.ShowHelp = $true;
            if ($sd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {$tDst.Text = $sd.FileName};
            $sd.Dispose();
        });
        $fmSrcDst.Controls.Add($btDstBrowse);
        
        $btCancel = New-Object System.Windows.Forms.Button;
        $btCancel.Text = $Strings.'btCancel.Text';
        $btCancel.Top = $tSrc.Height + $tDst.Height + 3 * 25;
        $btCancel.Left = $btSrcBrowse.Left;
        $btCancel.Add_Click({$fmSrcDst.DialogResult = [System.Windows.Forms.DialogResult]::Cancel});
        $fmSrcDst.Controls.Add($btCancel);
        $fmSrcDst.CancelButton = $btCancel;
        
        $btOk = New-Object System.Windows.Forms.Button;
        $btOk.Text = $Strings.'btOk.Text';
        $btOk.Enabled = $false;
        $btOk.Top = $btCancel.Top;
        $btOk.Left = $btCancel.Left - $btOk.Width - 25;
        $btOk.Add_Click({$fmSrcDst.DialogResult = [System.Windows.Forms.DialogResult]::OK});
        $fmSrcDst.Controls.Add($btOk);
        $fmSrcDst.AcceptButton = $btOk;
        
        $fmSrcDst.Height = (4*25 + $tSrc.Height + $tDst.Height + $btOk.Height) + $fmSrcDst.Height - $fmSrcDst.ClientRectangle.Height;
        $fmSrcDst.Width = 3*25 + $tSrc.Width + $btSrcBrowse.Width;
        
        $tSrc.Add_TextChanged({$btOk.Enabled = (($tSrc.Text -ne '') -and ($tDst.Text -ne ''));});

        $tDst.Add_TextChanged({$btOk.Enabled = (($tSrc.Text -ne '') -and ($tDst.Text -ne ''));});
        
        $fmSrcDst.MaximumSize = $fmSrcDst.MinimumSize = $fmSrcDst.Size;
        
        $fmSrcDst.ShowDialog();
        if ($fmSrcDst.DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
            Start-BitsTransfer -Source $tSrc.Text -Destination $tDst.Text -Asynchronous;
        }
        $fmSrcDst.Dispose();
    }, ([System.Windows.Forms.Keys]::Control -bOR [System.Windows.Forms.Keys]::N));
$miTmp.ShortcutKeyDisplayString = 'Ctrl+N';
$miItems = @($miTmp);

$miItems += New-Object System.Windows.Forms.ToolStripSeparator;

$miTmp = New-Object System.Windows.Forms.ToolStripMenuItem($Strings.'miExit', $null, {$MainWnd.DialogResult = [System.Windows.Forms.DialogResult]::Cancel},
    ([System.Windows.Forms.Keys]::Control -bOR [System.Windows.Forms.Keys]::X));
$miTmp.ShortcutKeyDisplayString = 'Ctrl+X';
$miItems += $miTmp;

$miMainTmp = New-Object System.Windows.Forms.ToolStripMenuItem($Strings.'miFile');
foreach ($miI in $miItems) {$miMainTmp.DropDownItems.Add($miI) | Out-Null;}
$miMain = @($miMainTmp);

$miTmp = New-Object System.Windows.Forms.ToolStripMenuItem($Strings.'miSuspend');
$miTmp.Name = 'miSuspend';
$miTmp.Enabled = $false;
$miTmp.Add_Click({
    $MainTable.SelectedItems | ForEach-Object {
        $tmp = Get-BitsTransfer -JobId $_.Name;
        if ($tmp.JobState -eq [Microsoft.BackgroundIntelligentTransfer.Management.BitsJobState]::Transferring){
            Suspend-BitsTransfer -BitsJob $tmp;
            $_.Selected = $false;
            $_.Selected = $true;
        }
    }
});
$miItems = @($miTmp);

$miTmp = New-Object System.Windows.Forms.ToolStripMenuItem($Strings.'miResume');
$miTmp.Name = "miResume";
$miTmp.Enabled = $false;
$miTmp.Add_Click({
    $MainTable.SelectedItems | ForEach-Object {
        $tmp = Get-BitsTransfer -JobId $_.Name;
        if ($tmp.JobState -eq [Microsoft.BackgroundIntelligentTransfer.Management.BitsJobState]::Suspended){
            Resume-BitsTransfer -BitsJob $tmp -Asynchronous;
            $_.Selected = $false;
            $_.Selected = $true;
        }
    }
});
$miItems += $miTmp;

$miTmp = New-Object System.Windows.Forms.ToolStripMenuItem($Strings.'miStop');
$miTmp.Name = 'miStop';
$miTmp.Enabled = $false;
$miTmp.Add_Click({
    $MainTable.SelectedItems | ForEach-Object {Get-BitsTransfer -JobId $_.Name | Remove-BitsTransfer;}
});
$miItems += $miTmp;

$miMainTmp = New-Object System.Windows.Forms.ToolStripMenuItem($Strings.'miEdit');
$miMainTmp.Name = 'miEdit';
foreach ($miI in $miItems) {$miMainTmp.DropDownItems.Add($miI) | Out-Null;}
$miMain += $miMainTmp;

$mm = New-Object System.Windows.Forms.MenuStrip;
foreach ($miMI in $miMain) {$mm.Items.Add($miMI) | Out-Null;}
$MainWnd.MainMenuStrip = $mm;
$MainWnd.Controls.Add($MainWnd.MainMenuStrip);
#Главное меню проинициализировано

#Инициализация таблицы
$MainTable = New-Object System.Windows.Forms.ListView;
$MainTable.Left = 0;
$MainTable.Top = $mm.Height;
$MainTable.Width = $MainWnd.ClientRectangle.Width;
$MainTable.Height = $MainWnd.ClientRectangle.Height - $mm.Height;
$MainTable.View = [System.Windows.Forms.View]::Details;
$MainTable.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D;
$MainTable.GridLines = $true;

$MainTable.Columns.Add($Strings.'MainTable.Columns.ID') | Out-Null;
$MainTable.Columns.Add($Strings.'MainTable.Columns.Caption') | Out-Null;
$MainTable.Columns.Add($Strings.'MainTable.Columns.Source') | Out-Null;
$MainTable.Columns.Add($Strings.'MainTable.Columns.Destination') | Out-Null;
$MainTable.Columns.Add($Strings.'MainTable.Columns.Sent') | Out-Null;
$MainTable.Columns.Add($Strings.'MainTable.Columns.Size') | Out-Null;
$MainTable.Columns.Add($Strings.'MainTable.Columns.State') | Out-Null;

$MainWnd.Controls.Add($MainTable);
#Таблица проинициализирована

#Инициализация таймера
$timer = New-Object System.Windows.Forms.Timer;
$timer.Interval = 1500;
#Таймер проинициализирован

#Обработчики событий
$MainWnd.Add_Resize({
    $MainTable.Width = $MainWnd.ClientRectangle.Width;
    $MainTable.Height = $MainWnd.ClientRectangle.Height - $mm.Height;
});

$timer.Add_Tick({
    Get-BitsTransfer | ForEach-Object {
        if (-not $MainTable.Items.ContainsKey($_.JobID.ToString())) {
            $BITSItem = New-Object System.Windows.Forms.ListViewItem($_.JobID.ToString(), 0);
            $BITSItem.Name = $_.JobID.ToString();
            $BITSItem.Subitems.Add($_.DisplayName) | Out-Null;
            $fRmt = '';
            $fLcl = '';
            $_.FileList | ForEach-Object {$fRmt += $_.RemoteName + "`n"; $fLcl += $_.LocalName + "`n";}
            $BITSItem.Subitems.Add($fRmt) | Out-Null;
            $BITSItem.Subitems.Add($fLcl) | Out-Null;
            $BITSItem.Subitems.Add($_.BytesTransferred) | Out-Null;
            $BITSItem.Subitems.Add($_.BytesTotal) | Out-Null;
            $BITSItem.Subitems.Add($_.JobState.ToString()) | Out-Null;
            $MainTable.Items.Add($BITSItem) | Out-Null;
        } elseif ($_.JobState -eq [Microsoft.BackgroundIntelligentTransfer.Management.BitsJobState]::Transferred) {
            $_ | Complete-BitsTransfer;
        } else {
            $MainTable.Items.Item($_.JobID.ToString()).SubItems.Item($BITSTransferred).Text = $_.BytesTransferred;
            if ($MainTable.Items.Item($_.JobID.ToString()).SubItems.Item($BITSState).Text -ne $_.JobState){
                $MainTable.Items.Item($_.JobID.ToString()).SubItems.Item($BITSState).Text = $_.JobState;
                $MainTable.Items[0].Selected = -not $MainTable.Items.Item(0).Selected;
                $MainTable.Items[0].Selected = -not $MainTable.Items.Item(0).Selected;
            }
            $MainTable.Items.Item($_.JobID.ToString()).SubItems.Item($BITSSize).Text = $_.BytesTotal;
        }
    }
    foreach ($item in $MainTable.Items){
        if ((Get-BitsTransfer -JobId $item.Name -ErrorAction SilentlyContinue) -eq $null){
            $MainTable.Items.Remove($item);
        }
    }
});

$MainTable.Add_SelectedIndexChanged({
    $ToSuspend = $ToStop = $ToResume = $false;
    foreach ($item in $MainTable.SelectedItems){
        $ToStop = $ToChange = $true;
        $tmp = Get-BitsTransfer -JobId $item.Name;
        if ($tmp.JobState -eq [Microsoft.BackgroundIntelligentTransfer.Management.BitsJobState]::Suspended) {$ToResume = $true;}
        elseif ($tmp.JobState -eq [Microsoft.BackgroundIntelligentTransfer.Management.BitsJobState]::Transferring) {$ToSuspend = $true;}
        if ($ToSuspend -and $ToStop -and $ToResume) {break;}
    }
    $mm.Items.Item("miEdit").DropDownItems.Item("miSuspend").Enabled = $ToSuspend;
    $mm.Items.Item("miEdit").DropDownItems.Item("miResume").Enabled = $ToResume;
    $mm.Items.Item("miEdit").DropDownItems.Item("miStop").Enabled = $ToStop;
});
#Все обработчики зарегистрированы

$timer.Start();
$MainWnd.ShowDialog();
$timer.Stop();

#Освобождение ресурсов
$timer.Dispose();
$MainWnd.Dispose()