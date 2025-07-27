import { Suspense } from 'react'
import RecoverContent from './recover-content'
import LoadingSpinner from '@/components/ui/loading-spinner'

export default function RecoverPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-red-100 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Password Recovery</h1>
          <p className="text-gray-600">
            Reset your password for your Studora account
          </p>
        </div>
        
        <Suspense fallback={<LoadingSpinner />}>
          <RecoverContent />
        </Suspense>
      </div>
    </div>
  )
}

export const metadata = {
  title: 'Password Recovery - Studora',
  description: 'Reset your password to regain access to your Studora account',
}
