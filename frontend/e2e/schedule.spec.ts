import { test, expect } from '@playwright/test'

test('schedule page populates city and facility dropdowns', async ({ page }) => {
  const email = process.env.SMOKE_USER_EMAIL!
  const password = process.env.SMOKE_USER_PASSWORD!

  // Log in via the real login form
  await page.goto('/login')
  await page.getByLabel(/email|correo electrónico/i).fill(email)
  await page.getByLabel(/password|contraseña/i).fill(password)
  await page.getByRole('button', { name: /log in|iniciar sesión/i }).click()
  await page.waitForURL((url) => !url.pathname.includes('login'))

  // Navigate to the schedule page
  await page.goto('/schedule')

  // City dropdown: must have options beyond "All" and a selected value
  const citySelect = page.locator('#city-filter')
  await expect(citySelect.locator('option')).not.toHaveCount(1)
  await expect(citySelect).not.toHaveValue('')

  // Facility dropdown: must have options beyond "All" and a selected value
  const facilitySelect = page.locator('#facility-filter')
  await expect(facilitySelect.locator('option')).not.toHaveCount(1)
  await expect(facilitySelect).not.toHaveValue('')
})
