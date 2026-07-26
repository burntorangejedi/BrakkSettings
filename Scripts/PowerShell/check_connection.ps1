param(
	[Parameter(Mandatory = $false)]
	[string[]]$Targets = @("192.168.0.1"),

	[Parameter(Mandatory = $false)]
	[int]$IntervalMs = 1000,

	[Parameter(Mandatory = $false)]
	[int]$TimeoutMs = 1500,

	[Parameter(Mandatory = $false)]
	[int]$AlertCooldownSeconds = 10,

	[Parameter(Mandatory = $false)]
	[switch]$NoClear,

	[Parameter(Mandatory = $false)]
	[switch]$QuietSuccess
)

if ($Targets.Count -eq 0) {
	Write-Error "No targets provided."
	exit 1
}

Add-Type -AssemblyName System

$pingJobs = @()
$targetState = @{}
$lastGlobalAlert = [datetime]::MinValue

foreach ($target in $Targets) {
	$t = $target.Trim()
	if ([string]::IsNullOrWhiteSpace($t)) {
		continue
	}

	$targetState[$t] = [pscustomobject]@{
		Target       = $t
		LastStatus   = "Starting"
		LastRttMs    = $null
		LastSeen     = $null
		Sent         = 0
		Success      = 0
		Timeout      = 0
		Error        = 0
		LastMessage  = ""
		LastEventAt  = Get-Date
	}

	$job = Start-Job -Name "Ping-$t" -ScriptBlock {
		param($Target, $Interval, $Timeout)

		$pinger = New-Object System.Net.NetworkInformation.Ping

		while ($true) {
			$now = Get-Date
			try {
				$reply = $pinger.Send($Target, $Timeout)
				if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
					[pscustomobject]@{
						Target    = $Target
						Timestamp = $now
						Ok        = $true
						Status    = "Success"
						RttMs     = [int]$reply.RoundtripTime
						Message   = "Reply in $($reply.RoundtripTime) ms"
					}
				} else {
					[pscustomobject]@{
						Target    = $Target
						Timestamp = $now
						Ok        = $false
						Status    = "Timeout"
						RttMs     = $null
						Message   = "Ping failed: $($reply.Status)"
					}
				}
			} catch {
				[pscustomobject]@{
					Target    = $Target
					Timestamp = $now
					Ok        = $false
					Status    = "Error"
					RttMs     = $null
					Message   = $_.Exception.Message
				}
			}

			Start-Sleep -Milliseconds $Interval
		}
	} -ArgumentList $t, $IntervalMs, $TimeoutMs

	$pingJobs += $job
}

if ($pingJobs.Count -eq 0) {
	Write-Error "No valid targets were provided after trimming."
	exit 1
}

Write-Host "Monitoring targets: $($targetState.Keys -join ', ')" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor DarkGray

$cleanup = {
	param($Jobs)
	foreach ($j in $Jobs) {
		try {
			Stop-Job -Job $j -ErrorAction SilentlyContinue | Out-Null
			Remove-Job -Job $j -Force -ErrorAction SilentlyContinue | Out-Null
		} catch {
			# Ignore cleanup errors so shutdown remains smooth.
		}
	}
}

try {
	while ($true) {
		foreach ($job in $pingJobs) {
			$updates = Receive-Job -Job $job -Keep -ErrorAction SilentlyContinue
			foreach ($u in $updates) {
				$state = $targetState[$u.Target]
				if (-not $state) {
					continue
				}

				$state.Sent++
				$state.LastSeen = $u.Timestamp
				$state.LastStatus = $u.Status
				$state.LastRttMs = $u.RttMs
				$state.LastMessage = $u.Message
				$state.LastEventAt = Get-Date

				if ($u.Ok) {
					$state.Success++
				} elseif ($u.Status -eq "Timeout") {
					$state.Timeout++
				} else {
					$state.Error++
				}

				if (-not $u.Ok) {
					$now = Get-Date
					$secondsSinceAlert = ($now - $lastGlobalAlert).TotalSeconds
					if ($secondsSinceAlert -ge $AlertCooldownSeconds) {
						$lastGlobalAlert = $now

						try {
							[console]::Beep(1200, 250)
							[console]::Beep(900, 250)
						} catch {
							try {
								[System.Media.SystemSounds]::Exclamation.Play()
							} catch {
							}
						}
					}
				}
			}
		}

		if (-not $NoClear) {
			Clear-Host
		}

		$rows = foreach ($key in ($targetState.Keys | Sort-Object)) {
			$s = $targetState[$key]
			$loss = if ($s.Sent -gt 0) { [math]::Round((($s.Sent - $s.Success) / $s.Sent) * 100, 1) } else { 0 }
			[pscustomobject]@{
				Target     = $s.Target
				Status     = $s.LastStatus
				LastRttMs  = $s.LastRttMs
				Sent       = $s.Sent
				Success    = $s.Success
				Timeout    = $s.Timeout
				Error      = $s.Error
				LossPct    = $loss
				LastSeen   = if ($s.LastSeen) { $s.LastSeen.ToString("HH:mm:ss") } else { "-" }
				LastMsg    = $s.LastMessage
			}
		}

		Write-Host "WoW Connection Monitor ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
		Write-Host "Targets: $($rows.Count) | Interval: ${IntervalMs}ms | Timeout: ${TimeoutMs}ms | Alert cooldown: ${AlertCooldownSeconds}s" -ForegroundColor DarkGray
		Write-Host ""

		$rows | Format-Table Target, Status, LastRttMs, Sent, Success, Timeout, Error, LossPct, LastSeen -AutoSize

		if (-not $QuietSuccess) {
			$latestProblems = $rows | Where-Object { $_.Status -ne "Success" }
			if ($latestProblems) {
				Write-Host ""
				Write-Host "Recent issues:" -ForegroundColor Yellow
				foreach ($p in $latestProblems) {
					Write-Host "[$($p.Target)] $($p.Status): $($p.LastMsg)" -ForegroundColor Red
				}
			}
		}

		Start-Sleep -Milliseconds 500
	}
} finally {
	& $cleanup $pingJobs
}
