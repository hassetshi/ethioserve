import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { logAdminAction } from '../lib/audit'
import { supabase } from '../lib/supabase'

type ProviderRow = {
  id: string
  business_name: string
  verification_status: string
  rating: number
  review_count: number
  phone: string
  cities: { name_en: string } | null
}

type DocumentRow = {
  id: string
  document_type: string
  storage_path: string
  verification_status: string
}

function StatusBadge({ status }: { status: string }) {
  const color =
    status === 'verified'
      ? 'bg-green-100 text-green-700'
      : status === 'rejected'
        ? 'bg-red-100 text-red-700'
        : status === 'suspended'
          ? 'bg-gray-200 text-gray-600'
          : 'bg-yellow-100 text-yellow-700'
  return <span className={`rounded px-2 py-0.5 text-xs capitalize ${color}`}>{status}</span>
}

function ProviderDocuments({ providerId }: { providerId: string }) {
  const { data } = useQuery({
    queryKey: ['provider-documents', providerId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('provider_documents')
        .select('id, document_type, storage_path, verification_status')
        .eq('provider_id', providerId)
      if (error) throw error

      const withUrls = await Promise.all(
        (data as DocumentRow[]).map(async (doc) => {
          const { data: signed } = await supabase.storage
            .from('provider-documents')
            .createSignedUrl(doc.storage_path, 3600)
          return { ...doc, url: signed?.signedUrl }
        }),
      )
      return withUrls
    },
  })

  if (!data || data.length === 0) {
    return <p className="text-sm text-gray-500">No documents submitted.</p>
  }

  return (
    <ul className="space-y-2">
      {data.map((doc) => (
        <li key={doc.id} className="text-sm">
          <a
            href={doc.url}
            target="_blank"
            rel="noreferrer"
            className="text-blue-600 hover:underline"
          >
            {doc.document_type}
          </a>
        </li>
      ))}
    </ul>
  )
}

export function ProvidersPage() {
  const queryClient = useQueryClient()
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const { data, isLoading, error } = useQuery({
    queryKey: ['providers'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('provider_profiles')
        .select('id, business_name, verification_status, rating, review_count, phone, cities(name_en)')
        .order('created_at', { ascending: false })
      if (error) throw error
      return data as unknown as ProviderRow[]
    },
  })

  async function setStatus(providerId: string, status: 'verified' | 'rejected' | 'suspended') {
    await supabase
      .from('provider_profiles')
      .update({ verification_status: status, verification_date: new Date().toISOString() })
      .eq('id', providerId)
    await logAdminAction(`provider.${status}`, 'provider_profiles', providerId)
    queryClient.invalidateQueries({ queryKey: ['providers'] })
  }

  if (isLoading) return <p>Loading...</p>
  if (error) return <p className="text-red-600">Something went wrong. Please try again.</p>

  const selected = data?.find((p) => p.id === selectedId)

  return (
    <div className="flex gap-6">
      <div className="flex-1">
        <h1 className="mb-4 text-xl font-semibold">Providers</h1>
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="border-b border-gray-200 text-left text-gray-500">
              <th className="py-2">Business</th>
              <th className="py-2">City</th>
              <th className="py-2">Rating</th>
              <th className="py-2">Status</th>
              <th className="py-2" />
            </tr>
          </thead>
          <tbody>
            {data?.map((provider) => (
              <tr key={provider.id} className="border-b border-gray-100">
                <td className="py-2">{provider.business_name}</td>
                <td className="py-2">{provider.cities?.name_en ?? '—'}</td>
                <td className="py-2">
                  {provider.rating.toFixed(1)} ({provider.review_count})
                </td>
                <td className="py-2">
                  <StatusBadge status={provider.verification_status} />
                </td>
                <td className="py-2">
                  <button
                    onClick={() => setSelectedId(provider.id)}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    Review
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selected && (
        <div className="w-80 shrink-0 rounded-lg border border-gray-200 p-4">
          <h2 className="mb-2 font-medium">{selected.business_name}</h2>
          <StatusBadge status={selected.verification_status} />
          <p className="mt-2 text-sm text-gray-600">{selected.phone}</p>

          <h3 className="mt-4 mb-2 text-sm font-medium">Documents</h3>
          <ProviderDocuments providerId={selected.id} />

          <div className="mt-4 flex gap-2">
            <button
              onClick={() => setStatus(selected.id, 'verified')}
              className="rounded bg-green-600 px-3 py-1.5 text-sm text-white"
            >
              Verify
            </button>
            <button
              onClick={() => setStatus(selected.id, 'rejected')}
              className="rounded bg-red-600 px-3 py-1.5 text-sm text-white"
            >
              Reject
            </button>
            <button
              onClick={() => setStatus(selected.id, 'suspended')}
              className="rounded border border-gray-300 px-3 py-1.5 text-sm"
            >
              Suspend
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
