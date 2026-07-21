export function useFacilities(_cityId?: number) {
  return { facilities: [] as readonly { id: number; name: string; cityId: number }[], isLoading: false, error: null }
}
