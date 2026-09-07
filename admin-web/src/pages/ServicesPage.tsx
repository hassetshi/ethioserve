import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { logAdminAction } from '../lib/audit'
import { supabase } from '../lib/supabase'

type ServiceRow = {
  id: string
  name_en: string
  name_am: string
  is_active: boolean
  category_id: string
  categories: { name_en: string } | null
}

type CategoryOption = { id: string; name_en: string }

export function ServicesPage() {
  const queryClient = useQueryClient()
  const [nameEn, setNameEn] = useState('')
  const [nameAm, setNameAm] = useState('')
  const [categoryId, setCategoryId] = useState('')

  const categoriesQuery = useQuery({
    queryKey: ['categories-options'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('categories')
        .select('id, name_en')
        .eq('is_active', true)
        .order('display_order')
      if (error) throw error
      return data as CategoryOption[]
    },
  })

  const { data, isLoading, error } = useQuery({
    queryKey: ['services'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('services')
        .select('id, name_en, name_am, is_active, category_id, categories(name_en)')
        .order('name_en')
      if (error) throw error
      return data as unknown as ServiceRow[]
    },
  })

  async function addService(e: FormEvent) {
    e.preventDefault()
    if (!nameEn.trim() || !nameAm.trim() || !categoryId) return
    const { data } = await supabase
      .from('services')
      .insert({ name_en: nameEn.trim(), name_am: nameAm.trim(), category_id: categoryId })
      .select('id')
      .single()
    if (data) {
      await logAdminAction('service.created', 'services', data.id, { name_en: nameEn.trim() })
    }
    setNameEn('')
    setNameAm('')
    queryClient.invalidateQueries({ queryKey: ['services'] })
  }

  async function toggleActive(service: ServiceRow) {
    const nextActive = !service.is_active
    await supabase.from('services').update({ is_active: nextActive }).eq('id', service.id)
    await logAdminAction(
      nextActive ? 'service.activated' : 'service.deactivated',
      'services',
      service.id,
    )
    queryClient.invalidateQueries({ queryKey: ['services'] })
  }

  if (isLoading) return <p>Loading...</p>
  if (error) return <p className="text-red-600">Something went wrong. Please try again.</p>

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Services</h1>

      <form onSubmit={addService} className="mb-6 flex flex-wrap gap-2">
        <select
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value)}
          className="rounded border border-gray-300 px-3 py-1.5 text-sm"
        >
          <option value="">Category...</option>
          {categoriesQuery.data?.map((category) => (
            <option key={category.id} value={category.id}>
              {category.name_en}
            </option>
          ))}
        </select>
        <input
          value={nameEn}
          onChange={(e) => setNameEn(e.target.value)}
          placeholder="Name (English)"
          className="rounded border border-gray-300 px-3 py-1.5 text-sm"
        />
        <input
          value={nameAm}
          onChange={(e) => setNameAm(e.target.value)}
          placeholder="Name (Amharic)"
          className="rounded border border-gray-300 px-3 py-1.5 text-sm"
        />
        <button type="submit" className="rounded bg-gray-900 px-3 py-1.5 text-sm text-white">
          Add
        </button>
      </form>

      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-gray-200 text-left text-gray-500">
            <th className="py-2">English</th>
            <th className="py-2">Amharic</th>
            <th className="py-2">Category</th>
            <th className="py-2">Status</th>
            <th className="py-2" />
          </tr>
        </thead>
        <tbody>
          {data?.map((service) => (
            <tr key={service.id} className="border-b border-gray-100">
              <td className="py-2">{service.name_en}</td>
              <td className="py-2">{service.name_am}</td>
              <td className="py-2">{service.categories?.name_en ?? '—'}</td>
              <td className="py-2">
                <span
                  className={`rounded px-2 py-0.5 text-xs ${
                    service.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                  }`}
                >
                  {service.is_active ? 'Active' : 'Inactive'}
                </span>
              </td>
              <td className="py-2">
                <button
                  onClick={() => toggleActive(service)}
                  className="text-xs text-blue-600 hover:underline"
                >
                  {service.is_active ? 'Deactivate' : 'Activate'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
