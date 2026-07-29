import { FormEvent, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, useNavigate } from 'react-router'
import { useCreateGymMember } from '../features/gym-members/useCreateGymMember'

const EMAIL_REGEXP = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export default function CreateGymMemberPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { create, isLoading, error: serverError } = useCreateGymMember()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [validationErrors, setValidationErrors] = useState<string[]>([])

  function validate(): string[] {
    const errors: string[] = []

    if (!email.trim()) {
      errors.push(t('gymMembers.emailRequired'))
    } else if (!EMAIL_REGEXP.test(email)) {
      errors.push(t('gymMembers.emailInvalid'))
    }

    if (!password) {
      errors.push(t('gymMembers.passwordRequired'))
    }

    return errors
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setValidationErrors([])

    const clientErrors = validate()
    if (clientErrors.length > 0) {
      setValidationErrors(clientErrors)
      return
    }

    const succeeded = await create(email, password)
    if (succeeded) {
      navigate('/gym-members')
    }
  }

  const allErrors = [...validationErrors]
  if (serverError && !allErrors.includes(serverError)) {
    allErrors.push(serverError)
  }

  return (
    <div className="min-h-dvh flex items-center justify-center px-4">
      <form className="w-full max-w-sm space-y-4" onSubmit={handleSubmit}>
        <h1 className="text-2xl font-bold">{t('gymMembers.createTitle')}</h1>

        <div>
          <label className="block text-sm font-medium mb-1" htmlFor="email">
            {t('gymMembers.email')}
          </label>
          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="min-h-11 w-full rounded border border-gray-300 px-3 py-2"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1" htmlFor="password">
            {t('gymMembers.password')}
          </label>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="new-password"
            required
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="min-h-11 w-full rounded border border-gray-300 px-3 py-2"
          />
        </div>

        {allErrors.length > 0 && (
          <ul role="alert" className="text-sm text-red-700 space-y-1">
            {allErrors.map((err) => (
              <li key={err}>{err}</li>
            ))}
          </ul>
        )}

        <button
          type="submit"
          disabled={isLoading}
          className="min-h-11 w-full rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-60"
        >
          {isLoading ? t('gymMembers.creating') : t('gymMembers.create')}
        </button>

        <p className="text-center">
          <Link to="/gym-members" className="text-sm text-blue-600 underline hover:text-blue-800">
            {t('gymMembers.backToList')}
          </Link>
        </p>
      </form>
    </div>
  )
}
