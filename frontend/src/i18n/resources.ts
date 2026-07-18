import esCO from './locales/es-CO/common.json'
import enUS from './locales/en-US/common.json'

export const defaultNS = 'common' as const

export const resources = {
  'es-CO': { common: esCO },
  'en-US': { common: enUS },
} as const
