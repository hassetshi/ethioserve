import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { logAdminAction } from '../lib/audit'
import { supabase } from '../lib/supabase'

type CategoryRow = {
  id: string
  name_en: string
  name_am: string
  is_active: boolean
  display_order: number
}

export function CategoriesPage() {
  const queryClient = useQueryClient()
  const [nameEn, setNameEn] = useState('')
  const [nameAm, setNameAm] = useState('')

  const { data, isLoading, error } = useQuery({
    queryKey: ['categories'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('categories')
        .select('id, name_en, name_am, is_active, display_order')
        .order('display_order')
      if (error) throw error
      return data as CategoryRow[]
    },
  })

  async function addCategory(e: FormEvent) {
    e.preventDefault()
    if (!nameEn.trim() || !nameAm.trim()) return
    const { data } = await supabase
      .from('categories')
      .insert({ name_en: nameEn.trim(), name_am: nameAm.trim() })
      .select('id')
      .single()
    if (data) {
      await logAdminAction('category.created', 'categories', data.id, { name_en: nameEn.trim() })
    }
    setNameEn('')
    setNameAm('')
    queryClient.invalidateQueries({ queryKey: ['categories'] })
  }

  async function toggleActive(category: CategoryRow) {
    const nextActive = !category.is_active
    await supabase.from('categories').update({ is_active: nextActive }).eq('id', category.id)
    await logAdminAction(
      nextActive ? 'category.activated' : 'category.deactivated',
      'categories',
      category.id,
    )
    queryClient.invalidateQueries({ queryKey: ['categories'] })
  }

  if (isLoading) return <p>Loading...</p>
  if (error) return <p className="text-red-600">Something went wrong. Please try again.</p>

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Categories</h1>

      <form onSubmit={addCategory} className="mb-6 flex gap-2">
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
            <th className="py-2">Status</th>
            <th className="py-2" />
          </tr>
        </thead>
        <tbody>
          {data?.map((category) => (
            <tr key={category.id} className="border-b border-gray-100">
              <td className="py-2">{category.name_en}</td>
              <td className="py-2">{category.name_am}</td>
              <td className="py-2">
                <span
                  className={`rounded px-2 py-0.5 text-xs ${
                    category.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                  }`}
                >
                  {category.is_active ? 'Active' : 'Inactive'}
                </span>
              </td>
              <td className="py-2">
                <button
                  onClick={() => toggleActive(category)}
                  className="text-xs text-blue-600 hover:underline"
                >
                  {category.is_active ? 'Deactivate' : 'Activate'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
