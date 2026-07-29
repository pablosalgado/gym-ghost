import { useState } from 'react'
import { Link } from 'react-router'
import { useTranslation } from 'react-i18next'
import { useGymMembers } from '../features/gym-members/useGymMembers'
import { useUpdateGymMember } from '../features/gym-members/useUpdateGymMember'
import type { GymMember } from '../lib/api-types'

export default function GymMembersPage() {
  const { t } = useTranslation()
  const { members, isLoading, error } = useGymMembers()
  const { updatePassword, isLoading: isUpdating, error: updateError } = useUpdateGymMember()

  const [expandedMemberId, setExpandedMemberId] = useState<number | null>(null)
  const [password, setPassword] = useState('')
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  function handleSubmit(member: GymMember) {
    return (e: React.FormEvent) => {
      e.preventDefault()
      if (password.length === 0) return
      setSuccessMessage(null)

      updatePassword(member.id, password).then((ok) => {
        if (ok) {
          setPassword('')
          setSuccessMessage(t('gymMembers.updateSuccess'))
        }
      })
    }
  }

  return (
    <div className="mx-auto max-w-4xl px-3 py-6 sm:px-4">
      <h1 className="text-2xl font-bold mb-6">{t('gymMembers.title')}</h1>

      <div className="mb-6">
        <Link
          to="/gym-members/new"
          className="inline-block min-h-11 rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
        >
          {t('gymMembers.create')}
        </Link>
      </div>

      {error !== null ? (
        <p className="py-12 text-center text-red-600">{error}</p>
      ) : isLoading ? (
        <p className="py-12 text-center text-gray-500">{t('common.loading')}</p>
      ) : members.length === 0 ? (
        <div className="py-12 text-center">
          <p className="text-gray-500 mb-4">{t('gymMembers.emptyState')}</p>
          <Link
            to="/gym-members/new"
            className="min-h-11 rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
          >
            {t('gymMembers.create')}
          </Link>
        </div>
      ) : (
        <ul className="flex flex-col gap-3">
          {members.map((member) => {
            const isExpanded = expandedMemberId === member.id
            return (
              <li
                key={member.id}
                className="rounded-lg border border-gray-200 p-4"
              >
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium truncate">
                    {member.email}
                  </span>
                  {!isExpanded ? (
                    <button
                      onClick={() => {
                        setExpandedMemberId(member.id)
                        setPassword('')
                        setSuccessMessage(null)
                      }}
                      className="min-h-11 min-w-11 rounded px-3 py-2 text-sm font-medium text-blue-600 hover:bg-blue-50"
                    >
                      {t('gymMembers.updatePassword')}
                    </button>
                  ) : (
                    <button
                      onClick={() => {
                        setExpandedMemberId(null)
                        setPassword('')
                        setSuccessMessage(null)
                      }}
                      className="min-h-11 min-w-11 rounded px-3 py-2 text-sm text-gray-500 hover:bg-gray-100"
                    >
                      ✕
                    </button>
                  )}
                </div>

                {isExpanded && (
                  <form
                    onSubmit={handleSubmit(member)}
                    className="mt-3 border-t border-gray-100 pt-3"
                  >
                    <p className="text-sm text-gray-600 mb-2">
                      {t('gymMembers.updatePasswordDescription')}
                    </p>
                    <label htmlFor={`password-${member.id}`} className="sr-only">
                      {t('gymMembers.password')}
                    </label>
                    <input
                      id={`password-${member.id}`}
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder={t('gymMembers.password')}
                      autoFocus
                      required
                      minLength={1}
                      className="w-full min-h-11 rounded border border-gray-300 px-3 py-2 mb-3"
                    />
                    {successMessage !== null ? (
                      <p className="text-sm text-green-600 mb-2">{successMessage}</p>
                    ) : updateError !== null ? (
                      <p className="text-sm text-red-600 mb-2">{updateError}</p>
                    ) : null}
                    <div className="flex gap-2 justify-end">
                      <button
                        type="button"
                        onClick={() => {
                          setExpandedMemberId(null)
                          setPassword('')
                          setSuccessMessage(null)
                        }}
                        className="min-h-11 rounded bg-gray-200 px-4 py-2 text-sm font-medium hover:bg-gray-300"
                      >
                        {t('gymMembers.cancel')}
                      </button>
                      <button
                        type="submit"
                        disabled={isUpdating || password.length === 0}
                        className="min-h-11 rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                      >
                        {isUpdating ? t('gymMembers.saving') : t('gymMembers.save')}
                      </button>
                    </div>
                  </form>
                )}
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
