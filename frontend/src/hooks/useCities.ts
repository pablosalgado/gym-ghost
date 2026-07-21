export function useCities() {
  return { cities: [] as readonly { id: number; name: string }[], isLoading: false, error: null }
}
