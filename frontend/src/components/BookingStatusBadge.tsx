type BookingStatus = 'pending' | 'booked' | 'failed' | 'available'

const DOT_BASE = 'inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full'

const INACTIVE_BG = 'bg-gray-200'
const INACTIVE_STROKE = 'stroke-gray-400'

const PENDING_BG = 'bg-amber-500'
const BOOKED_BG = 'bg-emerald-500'
const FAILED_BG = 'bg-red-500'

interface DotDef {
  key: BookingStatus
  label: string
  activeBg: string
  icon: React.ReactElement
}

const DOTS: readonly DotDef[] = [
  {
    key: 'pending',
    label: 'Pending',
    activeBg: PENDING_BG,
    icon: (
      <svg className="h-3 w-3" viewBox="0 0 12 12" fill="none" aria-hidden="true">
        <circle cx="6" cy="6" r="4.5" strokeWidth="1.5" />
        <path d="M6 4v2l1.5 1" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    key: 'booked',
    label: 'Booked',
    activeBg: BOOKED_BG,
    icon: (
      <svg className="h-3 w-3" viewBox="0 0 12 12" fill="none" aria-hidden="true">
        <path d="M2.5 6l2.5 2.5 4.5-5" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    key: 'failed',
    label: 'Failed',
    activeBg: FAILED_BG,
    icon: (
      <svg className="h-3 w-3" viewBox="0 0 12 12" fill="none" aria-hidden="true">
        <path d="M3.5 3.5l5 5m0-5l-5 5" strokeWidth="1.8" strokeLinecap="round" />
      </svg>
    ),
  },
]

function StatusDot({
  dot,
  active,
}: {
  dot: DotDef
  active: boolean
}) {
  const bg = active ? dot.activeBg : INACTIVE_BG
  const stroke = active ? 'stroke-white' : INACTIVE_STROKE

  return (
    <span
      className={`${DOT_BASE} ${bg} ${stroke}`}
      aria-label={dot.label}
      aria-current={active ? 'true' : undefined}
    >
      {dot.icon}
    </span>
  )
}

export interface BookingStatusBadgeProps {
  status: BookingStatus
  /** Formatted time label shown when pending. */
  pendingLabel?: string
  /** Retry handler for failed status. */
  onRetry?: () => void
  /** Whether the retry action is in progress. */
  isLoading?: boolean
  /** Retry button label. */
  retryLabel?: string
}

export type { BookingStatus }

export default function BookingStatusBadge({
  status}: BookingStatusBadgeProps) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="inline-flex items-center gap-0.5">
        {DOTS.map((dot) => (
          <StatusDot
            key={dot.key}
            dot={dot}
            active={dot.key === status}
          />
        ))}
      </span>
    </span>
  )
}
