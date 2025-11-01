echo "Installing GStreamer dev..."
curl -L ${{ matrix.gst_dev_url }} -o gstreamer-devel.msi
$args = '/i', 'gstreamer-devel.msi', '/qn', 'INSTALLDIR=C:\gstreamer', '/L*v', 'C:\install.log'
$process = Start-Process msiexec -ArgumentList $args -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Host "❌ GStreamer install failed with exit code $($process.ExitCode)"
    Get-Content C:\install.log -Tail 20
    exit 1
}
Write-Host "✅ GStreamer dev installed successfully"
curl -L ${{ matrix.gst_runtime_url }} -o gstreamer-runtime.msi
$args = '/i', 'gstreamer-runtime.msi', '/qn', 'INSTALLDIR=C:\gstreamer', '/L*v', 'C:\install.log'
$process = Start-Process msiexec -ArgumentList $args -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Host "❌ GStreamer install failed with exit code $($process.ExitCode)"
    Get-Content C:\install.log -Tail 20
    exit 1
}
Write-Host "✅ GStreamer installed successfully"
