export function calculateActivityKcalMultiplier(weightKg: number): number {
  const safeWeight = Number.isFinite(weightKg) && weightKg > 0 ? weightKg : 10;
  return Number.parseFloat(((safeWeight / 10) ** 0.7).toFixed(4));
}

export function calculateActivityKcalBurned(kcalPerMinute: number, durationMinutes: number, weightKg: number) {
  const multiplier = calculateActivityKcalMultiplier(weightKg);
  const total = kcalPerMinute * durationMinutes * multiplier;

  return {
    multiplier,
    kcalBurned: Number.parseFloat(total.toFixed(2)),
  };
}
