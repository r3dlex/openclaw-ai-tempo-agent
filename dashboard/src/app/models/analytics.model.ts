export interface DateRange {
  startDate: string;
  endDate: string;
}

export interface UsageRecord {
  dateRange: DateRange;
  creditsConsumed: string;
  groupKey: string;
}

export interface UserStats {
  email: string;
  total_credits: number;
  average_daily: number;
  days_active: number;
  last_active: string;
}

export interface DailyAggregate {
  date: string;
  total_credits: number;
  user_count: number;
}

export interface Summary {
  source: string;
  total_credits: number;
  total_users: number;
  active_users: number;
  days_tracked: number;
  average_credits_per_user: number;
}

export interface SourcesResponse {
  sources: string[];
}

export interface UserStatsResponse {
  source: string;
  users: UserStats[];
}

export interface DailyResponse {
  source: string;
  daily: DailyAggregate[];
}
