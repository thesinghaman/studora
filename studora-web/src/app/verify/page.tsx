import { Suspense } from 'react'
import VerifyContent from './verify-content'
import LoadingSpinner from '@/components/ui/loading-spinner'

export default function VerifyPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Email Verification</h1>
          <p className="text-gray-600">
            We&apos;re verifying your email address for Studora
          </p>
        </div>
        
        <Suspense fallback={<LoadingSpinner />}>
          <VerifyContent />
        </Suspense>
      </div>
    </div>
  )
}

export const metadata = {
  title: 'Verify Email - Studora',
  description: 'Verify your email address to complete your Studora account setup',
}
