"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { CheckCircle, XCircle, AlertCircle, Eye, EyeOff } from "lucide-react";

type RecoveryStatus = "validating" | "ready" | "success" | "error" | "expired";

export default function RecoverContent() {
  const searchParams = useSearchParams();
  const [status, setStatus] = useState<RecoveryStatus>("validating");
  const [message, setMessage] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const validateRecoveryLink = async () => {
      try {
        const userId = searchParams.get("userId");
        const secret = searchParams.get("secret");
        const expire = searchParams.get("expire");

        if (!userId || !secret) {
          setStatus("error");
          setMessage(
            "Invalid recovery link. Please request a new password reset."
          );
          return;
        }

        // Check if link has expired
        if (expire) {
          let expirationDate: Date;

          // Handle different expire formats
          if (expire.includes("T")) {
            // ISO format like "2025-07-26T20:47:22.257+00:00"
            expirationDate = new Date(decodeURIComponent(expire));
          } else {
            // Unix timestamp format
            expirationDate = new Date(parseInt(expire) * 1000);
          }

          if (expirationDate < new Date()) {
            setStatus("expired");
            setMessage(
              "This recovery link has expired. Please request a new one."
            );
            return;
          }
        }

        // If validation passes, allow user to set new password
        setStatus("ready");
        setMessage("Please enter your new password below.");
      } catch {
        setStatus("error");
        setMessage("An error occurred while validating the recovery link.");
      }
    };

    validateRecoveryLink();
  }, [searchParams]);

  const handlePasswordReset = async (e: React.FormEvent) => {
    e.preventDefault();

    if (password !== confirmPassword) {
      setMessage("Passwords do not match.");
      return;
    }

    if (password.length < 8) {
      setMessage("Password must be at least 8 characters long.");
      return;
    }

    setIsSubmitting(true);

    try {
      const userId = searchParams.get("userId");
      const secret = searchParams.get("secret");

      // Call our API endpoint which handles Appwrite password reset
      const response = await fetch("/api/reset-password", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ userId, secret, password }),
      });

      const result = await response.json();

      if (result.success) {
        setStatus("success");
        setMessage(
          result.message ||
            "Your password has been successfully reset! You can now log in with your new password."
        );
      } else {
        setStatus("error");
        setMessage(
          result.error ||
            "Failed to reset password. Please try again or contact support."
        );
      }
    } catch {
      setStatus("error");
      setMessage("An error occurred while resetting your password.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const getIcon = () => {
    switch (status) {
      case "success":
        return <CheckCircle className="w-16 h-16 text-green-500 mx-auto" />;
      case "error":
        return <XCircle className="w-16 h-16 text-red-500 mx-auto" />;
      case "expired":
        return <AlertCircle className="w-16 h-16 text-orange-500 mx-auto" />;
      default:
        return (
          <div className="w-16 h-16 mx-auto border-4 border-orange-200 border-t-orange-500 rounded-full animate-spin" />
        );
    }
  };

  const getStatusColor = () => {
    switch (status) {
      case "success":
        return "text-green-700";
      case "error":
        return "text-red-700";
      case "expired":
        return "text-orange-700";
      default:
        return "text-orange-700";
    }
  };

  if (status === "ready") {
    return (
      <form onSubmit={handlePasswordReset} className="space-y-6">
        <div className="text-center text-gray-600 mb-6">{message}</div>

        <div className="space-y-4">
          <div>
            <label
              htmlFor="password"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              New Password
            </label>
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                id="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 pr-10 placeholder-gray-500 text-black"
                placeholder="Enter your new password"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
          </div>

          <div>
            <label
              htmlFor="confirmPassword"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Confirm New Password
            </label>
            <div className="relative">
              <input
                type={showConfirmPassword ? "text" : "password"}
                id="confirmPassword"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 pr-10 placeholder-gray-500 text-black"
                placeholder="Confirm your new password"
                required
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600"
              >
                {showConfirmPassword ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={isSubmitting}
          className="w-full bg-orange-600 text-white py-2 px-4 rounded-lg hover:bg-orange-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSubmitting ? "Resetting Password..." : "Reset Password"}
        </button>
      </form>
    );
  }

  return (
    <div className="text-center">
      <div className="mb-6">{getIcon()}</div>

      <div className={`mb-6 ${getStatusColor()}`}>
        <h2 className="text-xl font-semibold mb-2">
          {status === "validating" && "Validating recovery link..."}
          {status === "success" && "Password Reset Successfully!"}
          {status === "error" && "Recovery Failed"}
          {status === "expired" && "Link Expired"}
        </h2>
        <p className="text-gray-600">{message}</p>
      </div>
    </div>
  );
}
