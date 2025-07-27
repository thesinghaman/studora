import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;

  // Protect verify route - must have userId and secret parameters
  if (pathname === "/verify") {
    const userId = searchParams.get("userId");
    const secret = searchParams.get("secret");

    if (!userId || !secret) {
      // Redirect to home page if required parameters are missing
      return NextResponse.redirect(new URL("/", request.url));
    }
  }

  // Protect recover route - must have userId and secret parameters
  if (pathname === "/recover") {
    const userId = searchParams.get("userId");
    const secret = searchParams.get("secret");

    if (!userId || !secret) {
      // Redirect to home page if required parameters are missing
      return NextResponse.redirect(new URL("/", request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/verify", "/recover"],
};
