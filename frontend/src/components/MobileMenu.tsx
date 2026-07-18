import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../hooks/useAuth'
import { useNavigate } from 'react-router'
import LanguageSwitcher from './LanguageSwitcher'

export default function MobileMenu() {
  const [isOpen, setIsOpen] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)
  const buttonRef = useRef<HTMLButtonElement>(null)
  const { logout } = useAuth()
  const { t } = useTranslation()
  const navigate = useNavigate()

  function handleLogout() {
    logout()
    navigate('/login')
  }

  function handleClose() {
    setIsOpen(false)
    buttonRef.current?.focus()
  }

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        menuRef.current &&
        !menuRef.current.contains(event.target as Node) &&
        buttonRef.current &&
        !buttonRef.current.contains(event.target as Node)
      ) {
        handleClose()
      }
    }

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        handleClose()
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
      document.addEventListener('keydown', handleEscape)
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
      document.removeEventListener('keydown', handleEscape)
    }
  }, [isOpen])

  return (
    <div className="sm:hidden">
      <button
        ref={buttonRef}
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        aria-controls="mobile-menu"
        aria-label={t('mobileMenu.toggle')}
        className="flex min-h-11 min-w-11 items-center justify-center rounded hover:bg-gray-100"
      >
        <svg
          className="h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth={1.5}
          stroke="currentColor"
          aria-hidden="true"
        >
          {isOpen ? (
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M6 18L18 6M6 6l12 12"
            />
          ) : (
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
            />
          )}
        </svg>
      </button>

      {isOpen && (
        <div
          ref={menuRef}
          id="mobile-menu"
          role="menu"
          className="absolute right-0 top-full z-50 mt-1 w-56 rounded border border-gray-200 bg-white shadow-lg"
        >
          <div className="p-3">
            <div className="mb-3">
              <LanguageSwitcher />
            </div>
            <button
              onClick={handleLogout}
              role="menuitem"
              className="w-full rounded bg-gray-200 px-4 py-2 text-left hover:bg-gray-300"
            >
              {t('auth.logOut')}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
