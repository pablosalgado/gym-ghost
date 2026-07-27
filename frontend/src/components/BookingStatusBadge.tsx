import type { ReactElement } from 'react'

type BookingStatus = 'pending' | 'booked' | 'failed'

const STATUS_CONFIG: Record<
  BookingStatus,
  { bg: string; icon: ReactElement; label: string }
> = {
  pending: {
    bg: 'bg-amber-500',
    label: 'Pending',
    icon: (
      <svg
        className="h-3 w-3"
        viewBox="0 0 12 12"
        fill="none"
        aria-hidden="true"
      >
        <circle
          cx="6"
          cy="6"
          r="4.5"
          stroke="white"
          strokeWidth="1.5"
        />
        <path
          d="M6 4v2l1.5 1"
          stroke="white"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    ),
  },
  booked: {
    bg: 'bg-emerald-500',
    label: 'Booked',
    icon: (
      <svg
        className="h-3 w-3"
        viewBox="0 0 12 12"
        fill="none"
        aria-hidden="true"
      >
        <path
          d="M2.5 6l2.5 2.5 4.5-5"
          stroke="white"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    ),
  },
  failed: {
    bg: 'bg-red-500',
    label: 'Failed',
    icon: (
      <svg
        className="h-3 w-3"
        viewBox="0 0 12 12"
        fill="none"
        aria-hidden="true"
      >
        <path
          d="M6 4v3m0 2h.005"
          stroke="white"
          strokeWidth="1.8"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
}

function StatusDot({ status }: { status: BookingStatus }) {
  const config = STATUS_CONFIG[status]

  return (
    <span
      className={`inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full ${config.bg}`}
      aria-label={config.label}
    >
      {config.icon}
    </span>
  )
}

export interface BookingStatusBadgeProps {
  status: BookingStatus
  /** Formatted time label shown next to the pending icon. */
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
  status,
  pendingLabel,
  onRetry,
  isLoading = false,
  retryLabel = 'Retry',
}: BookingStatusBadgeProps) {
  if (status === 'pending') {
    return (
      <span className="inline-flex items-center gap-1.5 text-sm">
        <StatusDot status="pending" />
        {pendingLabel && (
          <span className="text-gray-500">{pendingLabel}</span>
        )}
      </span>
    )
  }

  if (status === 'booked') {
    return <StatusDot status="booked" />
  }

  // failed
  return (
    <span className="inline-flex items-center gap-2">
      <StatusDot status="failed" />
      {onRetry && (
        <button
          type="button"
          onClick={onRetry}
          disabled={isLoading}
          className="min-h-11 min-w-11 rounded bg-red-100 px-3 py-2 text-sm font-medium text-red-700 hover:bg-red-200 disabled:opacity-50"
        >
          {retryLabel}
        </button>
      )}
    </span>
  )
}
