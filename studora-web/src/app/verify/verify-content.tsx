'use client'

import { useEffect, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import { CheckCircle, XCircle, AlertCircle } from 'lucide-react'

type VerificationStatus = 'verifying' | 'success' | 'error' | 'expired'

export default function VerifyContent() {
  const searchParams = useSearchParams()
  const [status, setStatus] = useState<VerificationStatus>('verifying')
  const [message, setMessage] = useState('')

  useEffect(() => {
    const verifyEmail = async () => {
      try {
        const userId = searchParams.get('userId')
        const secret = searchParams.get('secret')
        const expire = searchParams.get('expire')

        if (!userId || !secret) {
          setStatus('error')
          setMessage('Invalid verification link. Please try requesting a new verification email.')
          return
        }

        // Check if link has expired
        if (expire) {
          let expirationDate: Date

          // Handle different expire formats
          if (expire.includes('T')) {
            // ISO format like "2025-07-26T20:47:22.257+00:00"
            expirationDate = new Date(decodeURIComponent(expire))
          } else {
            // Unix timestamp format
            expirationDate = new Date(parseInt(expire) * 1000)
          }

          if (expirationDate < new Date()) {
            setStatus('expired')
            setMessage('This verification link has expired. Please request a new one.')
            return
          }
        }

        // Call our API endpoint which handles Appwrite verification
        const response = await fetch('/api/verify-email', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ userId, secret }),
        })

        const result = await response.json()

        if (result.success) {
          setStatus('success')
          setMessage(result.message || 'Your email has been successfully verified! You can now use all features of Studora.')
        } else {
          setStatus('error')
          setMessage(result.error || 'Verification failed. Please try again or contact support.')
        }
      } catch {
        setStatus('error')
        setMessage('An error occurred during verification. Please try again.')
      }
    }

    verifyEmail()
  }, [searchParams])

  const getIcon = () => {
    switch (status) {
      case 'success':
        return <CheckCircle className="w-16 h-16 text-green-500 mx-auto" />
      case 'error':
        return <XCircle className="w-16 h-16 text-red-500 mx-auto" />
      case 'expired':
        return <AlertCircle className="w-16 h-16 text-orange-500 mx-auto" />
      default:
        return (
          <div className="w-16 h-16 mx-auto border-4 border-blue-200 border-t-blue-500 rounded-full animate-spin" />
        )
    }
  }

  const getStatusColor = () => {
    switch (status) {
      case 'success':
        return 'text-green-700'
      case 'error':
        return 'text-red-700'
      case 'expired':
        return 'text-orange-700'
      default:
        return 'text-blue-700'
    }
  }

  return (
    <div className="text-center">
      <div className="mb-6">
        {getIcon()}
      </div>

      <div className={`mb-6 ${getStatusColor()}`}>
        <h2 className="text-xl font-semibold mb-2">
          {status === 'verifying' && 'Verifying your email...'}
          {status === 'success' && 'Email Verified!'}
          {status === 'error' && 'Verification Failed'}
          {status === 'expired' && 'Link Expired'}
        </h2>
        <p className="text-gray-600">{message}</p>
      </div>
    </div>
  )
}
