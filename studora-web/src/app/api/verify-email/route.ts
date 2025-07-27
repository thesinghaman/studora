import { NextRequest, NextResponse } from 'next/server'
import { Client, Account } from 'node-appwrite'

export async function POST(request: NextRequest) {
  try {
    const { userId, secret } = await request.json()

    if (!userId || !secret) {
      return NextResponse.json(
        { success: false, error: 'Missing userId or secret' },
        { status: 400 }
      )
    }

    // Validate environment variables
    if (!process.env.APPWRITE_ENDPOINT || !process.env.APPWRITE_PROJECT_ID) {
      console.error('Missing Appwrite configuration')
      return NextResponse.json(
        { success: false, error: 'Server configuration error' },
        { status: 500 }
      )
    }

    // Initialize Appwrite client
    const client = new Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_PROJECT_ID)

    const account = new Account(client)

    // Verify the email using Appwrite's verification API
    await account.updateVerification(userId, secret)

    return NextResponse.json({
      success: true,
      message: 'Email verified successfully'
    })

  } catch (error: unknown) {
    console.error('Email verification error:', error)
    
    // Handle specific Appwrite errors
    const appwriteError = error as { code?: number; type?: string; message?: string }
    
    if (appwriteError.code === 401) {
      return NextResponse.json(
        { success: false, error: 'Invalid or expired verification link' },
        { status: 400 }
      )
    }
    
    if (appwriteError.code === 404) {
      return NextResponse.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      )
    }

    if (appwriteError.type === 'user_already_verified') {
      return NextResponse.json(
        { success: true, message: 'Email is already verified' }
      )
    }

    return NextResponse.json(
      { success: false, error: 'Verification failed. Please try again.' },
      { status: 500 }
    )
  }
}
