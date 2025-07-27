import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/auth/controllers/signup_controller.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
import 'package:studora/app/data/models/country_model.dart';
class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    InputDecoration customInputDecoration(
      String label,
      IconData iconData, {
      Widget? suffixIcon,
      String? hintText,
      bool enabled = true,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hintText ?? "Enter $label",
        prefixIcon: Icon(
          iconData,
          color: theme.iconTheme.color?.withValues(alpha: 0.7),
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: enabled
                ? theme.dividerColor.withValues(alpha: 0.5)
                : theme.disabledColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: enabled ? theme.colorScheme.primary : theme.disabledColor,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: theme.disabledColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        filled: true,
        fillColor: enabled
            ? (theme.inputDecorationTheme.fillColor ??
                  theme.colorScheme.surfaceContainerLowest)
            : theme.disabledColor.withValues(alpha: 0.05),
      );
    }
    Widget buildCountryDropdown() {
      return Obx(() {
        if (controller.isLoadingCountries.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CupertinoActivityIndicator(),
            ),
          );
        }
        if (controller.countriesError.value != null) {
          return InkWell(
            onTap: controller.fetchInitialData,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.error),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.countriesError.value!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  Icon(Icons.refresh, color: theme.colorScheme.error, size: 20),
                ],
              ),
            ),
          );
        }
        if (controller.supportedCountries.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(10.0),
              color: theme.disabledColor.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Text(
                "No countries available",
                style: TextStyle(color: theme.hintColor),
              ),
            ),
          );
        }
        return DropdownButtonFormField<CountryModel>(
          decoration: customInputDecoration(
            "Select Your Country",
            Icons.public_outlined,
          ),
          value: controller.selectedCountry.value,
          hint: const Text("Select country"),
          items: controller.supportedCountries.map((country) {
            return DropdownMenuItem<CountryModel>(
              value: country,
              child: Text(country.name),
            );
          }).toList(),
          onChanged: (CountryModel? newValue) {
            controller.onCountrySelected(newValue?.name);
          },
          validator: (value) =>
              value == null ? 'Please select your country' : null,
          isExpanded: true,
        );
      });
    }
    Widget buildCollegeSelector() {
      return Obx(() {
        bool isCountrySelected = controller.selectedCountry.value != null;
        bool showCollegeLoader =
            isCountrySelected &&
            controller.isLoadingColleges.value &&
            controller.countriesError.value == null;
        if (showCollegeLoader) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CupertinoActivityIndicator(),
            ),
          );
        }
        if (isCountrySelected &&
            controller.collegesError.value != null &&
            controller.countriesError.value == null) {
          return InkWell(
            onTap: controller.fetchCollegesAndFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.error),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.collegesError.value!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  Icon(Icons.refresh, color: theme.colorScheme.error, size: 20),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller.collegeDisplayController,
              readOnly: true,
              decoration: customInputDecoration(
                "Select Your College",
                Icons.school_outlined,
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: isCountrySelected
                      ? (theme.iconTheme.color?.withValues(alpha: 0.7))
                      : theme.disabledColor.withValues(alpha: 0.7),
                ),
                hintText: isCountrySelected
                    ? "Tap to select college"
                    : "Select country first",
                enabled:
                    isCountrySelected && controller.collegesError.value == null,
              ),
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                color:
                    (isCountrySelected &&
                        controller.collegesError.value == null)
                    ? theme.textTheme.bodyLarge?.color
                    : theme.disabledColor,
              ),
              onTap:
                  (isCountrySelected && controller.collegesError.value == null)
                  ? controller.openCollegeSelectionModal
                  : null,
              validator: (value) {
                if (isCountrySelected &&
                    controller.collegesError.value == null &&
                    (value == null || value.isEmpty)) {
                  return 'Please select your college';
                }
                return null;
              },
            ),
            if (!isCountrySelected)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                child: Text(
                  "Please select your country first.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      });
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Create Account",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: controller.navigateToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.01,
          ),
          child: Obx(
            () => Form(
              key: controller.formKey,
              autovalidateMode: controller.hasAttemptedSignup.value
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: screenHeight * 0.01),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      "Let's Get Started!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 250),
                    child: Text(
                      "Create an account to join the Studora community.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: buildCountryDropdown(),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 350),
                    child: buildCollegeSelector(),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: TextFormField(
                      controller: controller.nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: customInputDecoration(
                        "Full Name",
                        Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.length < 3) {
                          return 'Full name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 425),
                    child: TextFormField(
                      controller: controller.rollNumberController,
                      keyboardType: TextInputType.text,
                      decoration: customInputDecoration(
                        "Roll Number / Student ID",
                        Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your roll number or student ID';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 450),
                    child: Obx(
                      () => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: controller.emailPrefixController,
                              keyboardType: TextInputType.text,
                              enabled: controller.selectedCollege.value != null,
                              decoration: customInputDecoration(
                                "Student Email",
                                Icons.mail_outline,
                                hintText:
                                    controller.selectedCollege.value != null
                                    ? "your.name"
                                    : "Select college first",
                                enabled:
                                    controller.selectedCollege.value != null,
                              ),
                              validator: (value) {
                                if (controller.selectedCollege.value == null &&
                                    (value != null && value.isNotEmpty)) {
                                  return 'Select college to set domain';
                                }
                                if (controller.selectedCollege.value != null &&
                                    (value == null || value.isEmpty)) {
                                  return 'Email prefix required';
                                }
                                if (value != null && value.contains('@')) {
                                  return 'Enter only part before @';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Expanded(
                            flex: 2,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color:
                                        (controller.selectedCollege.value !=
                                            null)
                                        ? theme.dividerColor.withValues(
                                            alpha: 0.5,
                                          )
                                        : theme.disabledColor.withValues(
                                            alpha: 0.3,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color:
                                        (controller.selectedCollege.value !=
                                            null)
                                        ? theme.dividerColor.withValues(
                                            alpha: 0.5,
                                          )
                                        : theme.disabledColor.withValues(
                                            alpha: 0.3,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: theme.disabledColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 17,
                                ),
                                filled: true,
                                fillColor: theme.disabledColor.withValues(
                                  alpha: 0.05,
                                ),
                              ),
                              child: Obx(
                                () => Text(
                                  controller.emailDomain.value.isNotEmpty
                                      ? controller.emailDomain.value
                                      : "@...",
                                  style: TextStyle(
                                    color:
                                        controller.emailDomain.value.isNotEmpty
                                        ? theme.colorScheme.onSurfaceVariant
                                        : theme.hintColor,
                                    fontSize: 15,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: Obx(
                      () => TextFormField(
                        controller: controller.passwordController,
                        obscureText: !controller.isPasswordVisible.value,
                        decoration: customInputDecoration(
                          "Password",
                          Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: theme.iconTheme.color?.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 550),
                    child: Obx(
                      () => TextFormField(
                        controller: controller.confirmPasswordController,
                        obscureText: !controller.isConfirmPasswordVisible.value,
                        decoration: customInputDecoration(
                          "Confirm Password",
                          Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isConfirmPasswordVisible.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: theme.iconTheme.color?.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            onPressed:
                                controller.toggleConfirmPasswordVisibility,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != controller.passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: Obx(
                      () => Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: controller.agreedToTerms.value,
                            activeColor: theme.colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                            onChanged: controller.toggleAgreedToTerms,
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                children: [
                                  const TextSpan(text: "I agree to the "),
                                  TextSpan(
                                    text: "Terms & Conditions",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = controller.navigateToTerms,
                                  ),
                                  const TextSpan(text: " and "),
                                  TextSpan(
                                    text: "Privacy Policy",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = controller.navigateToPrivacy,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 650),
                    child: Obx(
                      () => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: controller.isSigningUp.value
                            ? null
                            : controller.signupUser,
                        child: controller.isSigningUp.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text("Sign Up"),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 700),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Already have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.navigateToLogin,
                          child: Text(
                            "Login",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
