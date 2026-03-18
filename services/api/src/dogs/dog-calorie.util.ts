import { ActivityLevel } from './dto/create-dog.dto';

export type DogCalorieProfile = {
  birthdate?: string | Date;
  activityLevel?: ActivityLevel;
  isNeutered?: boolean;
  currentWeightKg?: number;
  targetWeightKg?: number;
};

export function calculateDogDailyKcal(profile: DogCalorieProfile): number | null {
  const referenceWeight = profile.targetWeightKg ?? profile.currentWeightKg;
  if (referenceWeight == null || referenceWeight <= 0) {
    return null;
  }

  const rer = 70 * Math.pow(referenceWeight, 0.75);
  const ageInMonths = getAgeInMonths(profile.birthdate);
  const factor = getMaintenanceFactor({
    ageInMonths,
    activityLevel: profile.activityLevel ?? ActivityLevel.MEDIUM,
    isNeutered: profile.isNeutered ?? false,
  });

  return Math.round(rer * factor);
}

function getAgeInMonths(birthdate?: string | Date): number | null {
  if (!birthdate) return null;
  const value = birthdate instanceof Date ? birthdate : new Date(birthdate);
  if (Number.isNaN(value.getTime())) return null;

  const now = new Date();
  const yearDiff = now.getFullYear() - value.getFullYear();
  const monthDiff = now.getMonth() - value.getMonth();
  const dayDiff = now.getDate() - value.getDate();
  let totalMonths = yearDiff * 12 + monthDiff;
  if (dayDiff < 0) totalMonths -= 1;
  return Math.max(totalMonths, 0);
}

function getMaintenanceFactor({
  ageInMonths,
  activityLevel,
  isNeutered,
}: {
  ageInMonths: number | null;
  activityLevel: ActivityLevel;
  isNeutered: boolean;
}): number {
  if (ageInMonths != null) {
    if (ageInMonths < 4) return 3;
    if (ageInMonths < 12) return 2;
    if (ageInMonths >= 84) {
      return seniorFactor(activityLevel, isNeutered);
    }
  }

  const base = isNeutered ? 1.6 : 1.8;
  switch (activityLevel) {
    case ActivityLevel.LOW:
      return Math.max(1.2, base - 0.2);
    case ActivityLevel.HIGH:
      return base + 0.4;
    case ActivityLevel.MEDIUM:
    default:
      return base;
  }
}

function seniorFactor(activityLevel: ActivityLevel, isNeutered: boolean): number {
  const base = isNeutered ? 1.2 : 1.4;
  if (activityLevel === ActivityLevel.HIGH) return base + 0.2;
  if (activityLevel === ActivityLevel.LOW) return Math.max(1, base - 0.1);
  return base;
}
