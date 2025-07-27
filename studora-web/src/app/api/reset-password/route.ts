import { NextRequest, NextResponse } from 'next/server'
import { Client, Account } from 'node-appwrite'

export async function POST(request: NextRequest) {
  try {
    const { userId, secret, password } = await request.json()

    if (!userId || !secret || !password) {
      return NextResponse.json(
        { success: false, error: 'Missing required fields' },
        { status: 400 }
      )
    }

    if (password.length < 8) {
      return NextResponse.json(
        { success: false, error: 'Password must be at least 8 characters' },
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

    // Reset the password using Appwrite's recovery API
    await account.updateRecovery(userId, secret, password)

    return NextResponse.json({
      success: true,
      message: 'Password reset successfully'
    })

  } catch (error: unknown) {
    console.error('Password reset error:', error)
    
    // Handle specific Appwrite errors
    const appwriteError = error as { code?: number; type?: string; message?: string }
    
    if (appwriteError.code === 401) {
      return NextResponse.json(
        { success: false, error: 'Invalid or expired recovery link' },
        { status: 400 }
      )
    }
    
    if (appwriteError.code === 404) {
      return NextResponse.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      )
    }

    if (appwriteError.type === 'user_password_mismatch') {
      return NextResponse.json(
        { success: false, error: 'Password confirmation does not match' },
        { status: 400 }
      )
    }

    if (appwriteError.type === 'password_recently_used') {
      return NextResponse.json(
        { success: false, error: 'Please choose a different password' },
        { status: 400 }
      )
    }

    return NextResponse.json(
      { success: false, error: 'Password reset failed. Please try again.' },
      { status: 500 }
    )
  }
}
