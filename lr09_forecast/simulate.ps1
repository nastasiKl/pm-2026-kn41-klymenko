# Reproducible Monte Carlo for LR09. Run from the repository root:
# pwsh -File .\lr09_forecast\simulate.ps1
$ErrorActionPreference = 'Stop'
$runs = 10000

function Get-PercentileCeiling([int[]]$values, [double]$percentile) {
    $ordered = @($values | Sort-Object)
    $position = ($ordered.Count - 1) * $percentile
    $lower = [int][math]::Floor($position)
    $upper = [int][math]::Ceiling($position)
    $fraction = $position - $lower
    $value = $ordered[$lower] + ($ordered[$upper] - $ordered[$lower]) * $fraction
    return [int][math]::Ceiling($value)
}

function Invoke-Forecast([string]$name, [int]$points, [int[]]$velocity, [long]$seed) {
    $results = [int[]]::new($runs)
    $state = $seed
    for ($i = 0; $i -lt $runs; $i++) {
        $remaining = $points
        $sprints = 0
        while ($remaining -gt 0) {
            # Fixed LCG makes this run reproducible across machines.
            $state = (($state * 1664525L + 1013904223L) % 4294967296L)
            # Use high LCG bits; low bits alternate and are unsuitable for sampling.
            $index = [int][math]::Floor(($state / 4294967296.0) * $velocity.Count)
            $remaining -= $velocity[$index]
            $sprints++
        }
        $results[$i] = $sprints
    }
    [pscustomobject]@{
        source = $name
        points = $points
        simulations = $runs
        p50 = Get-PercentileCeiling $results 0.50
        p85 = Get-PercentileCeiling $results 0.85
    }
}

$reference = @(21,17,26,14,23,6,28,12,22,25,18,9)
$myVelocity = @(9,10)
@(
    Invoke-Forecast 'my_all' 58 $myVelocity 9001
    Invoke-Forecast 'my_remaining' 39 $myVelocity 9002
    Invoke-Forecast 'reference_all' 220 $reference 9003
    Invoke-Forecast 'reference_1_2' 220 @($reference[0],$reference[1]) 9004
    Invoke-Forecast 'reference_5_6' 220 @($reference[4],$reference[5]) 9005
) | Format-Table -AutoSize
