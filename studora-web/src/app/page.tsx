import Link from "next/link";
import { BookOpen, MessageSquare, ShoppingBag, Users, Github, Smartphone, Globe } from "lucide-react";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Navigation */}
      <nav className="container mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="text-2xl font-bold text-blue-600">
            Studora
          </div>
          <div className="hidden md:flex items-center space-x-8">
            <Link href="#about" className="text-gray-600 hover:text-gray-900 transition-colors">
              About
            </Link>
            <Link href="#roadmap" className="text-gray-600 hover:text-gray-900 transition-colors">
              Roadmap
            </Link>
            <Link href="#contribute" className="text-gray-600 hover:text-gray-900 transition-colors">
              Contribute
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container mx-auto px-6 py-20">
        <div className="text-center max-w-4xl mx-auto">
          <div className="inline-flex items-center gap-2 bg-blue-100 text-blue-800 px-4 py-2 rounded-full text-sm font-medium mb-6">
            <div className="w-2 h-2 bg-blue-600 rounded-full animate-pulse"></div>
            Project in Development
          </div>
          <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
            Your Campus
            <span className="text-blue-600"> Marketplace</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8 leading-relaxed">
            An innovative platform designed to connect college communities through buying, selling,
            lost & found, messaging, and campus discoveries. Currently under active development.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <a
              href="https://github.com/thesinghaman/studora"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-blue-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2"
            >
              <Github size={20} />
              View on GitHub
            </a>
            <a
              href="/APKs/app-release.apk"
              download="studora-app.apk"
              className="border border-gray-300 text-gray-700 px-8 py-4 rounded-lg text-lg font-semibold hover:bg-gray-50 transition-colors flex items-center gap-2"
            >
              <Smartphone size={20} />
              Download APK
            </a>
          </div>
        </div>
      </section>

      {/* About Section */}
      <section id="about" className="py-20 bg-white">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              About Studora
            </h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Studora is an innovative campus marketplace and community platform designed to enhance
              the college experience. This is an ongoing open-source project that aims to create a
              comprehensive ecosystem for students to connect, trade, and collaborate.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div className="text-center p-6">
              <div className="bg-blue-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <ShoppingBag className="text-blue-600" size={32} />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Campus Marketplace</h3>
              <p className="text-gray-600">
                Buy and sell textbooks, electronics, furniture, and more with fellow students safely.
              </p>
            </div>

            <div className="text-center p-6">
              <div className="bg-green-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <MessageSquare className="text-green-600" size={32} />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Secure Messaging</h3>
              <p className="text-gray-600">
                Chat safely with other students through our built-in real-time messaging system.
              </p>
            </div>

            <div className="text-center p-6">
              <div className="bg-purple-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <BookOpen className="text-purple-600" size={32} />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Lost & Found</h3>
              <p className="text-gray-600">
                Report lost items and help others find their belongings around campus efficiently.
              </p>
            </div>

            <div className="text-center p-6">
              <div className="bg-orange-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="text-orange-600" size={32} />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Community Building</h3>
              <p className="text-gray-600">
                Connect with your college community and discover everything campus has to offer.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Development Roadmap */}
      <section id="roadmap" className="py-20 bg-gray-50">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Development Roadmap
            </h2>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Track our progress as we build the ultimate campus community platform
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <div className="space-y-8">
              {/* Phase 1 */}
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0">
                  <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm font-bold">✓</span>
                  </div>
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-gray-900 mb-2 flex items-center gap-2">
                    <Smartphone size={20} />
                    Phase 1: Mobile App Development (In Progress)
                  </h3>
                  <p className="text-gray-600 mb-2">
                    Building the core mobile application with Flutter for iOS and Android platforms.
                  </p>
                  <div className="text-sm text-gray-500">
                    ✅ User Authentication & Profiles<br/>
                    ✅ Marketplace Functionality<br/>
                    ✅ Real-time Messaging<br/>
                    ✅ Lost & Found System<br/>
                    🔄 Testing & Refinements
                  </div>
                </div>
              </div>

              {/* Phase 2 */}
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0">
                  <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm font-bold">2</span>
                  </div>
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-gray-900 mb-2 flex items-center gap-2">
                    <Smartphone size={20} />
                    Phase 2: Mobile App Release (Coming Soon)
                  </h3>
                  <p className="text-gray-600 mb-2">
                    Launch the mobile app on App Store and Google Play Store for public use.
                  </p>
                  <div className="text-sm text-gray-500">
                    📱 iOS App Store Release<br/>
                    📱 Google Play Store Release<br/>
                    📊 User Feedback Collection<br/>
                    🐛 Bug Fixes & Improvements
                  </div>
                </div>
              </div>

              {/* Phase 3 */}
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0">
                  <div className="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
                    <span className="text-gray-600 text-sm font-bold">3</span>
                  </div>
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-gray-900 mb-2 flex items-center gap-2">
                    <Globe size={20} />
                    Phase 3: Web Platform Development (Future)
                  </h3>
                  <p className="text-gray-600 mb-2">
                    After successful mobile app launch, develop a comprehensive web platform.
                  </p>
                  <div className="text-sm text-gray-500">
                    🌐 Full Web Application<br/>
                    💻 Desktop-Optimized Experience<br/>
                    🔗 Cross-Platform Synchronization<br/>
                    📈 Advanced Analytics & Features
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Contribution Section */}
      <section id="contribute" className="py-20 bg-white">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Join Our Development Journey
            </h2>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Studora is an open-source project. We welcome contributions from developers,
              designers, and students who want to help build the future of campus communities.
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <div className="grid md:grid-cols-2 gap-8 mb-12">
              <div className="bg-gray-50 p-8 rounded-lg">
                <h3 className="text-2xl font-semibold text-gray-900 mb-4">For Developers</h3>
                <ul className="space-y-2 text-gray-600">
                  <li>• Flutter mobile app development</li>
                  <li>• Next.js web platform (future)</li>
                  <li>• Backend API improvements</li>
                  <li>• UI/UX enhancements</li>
                  <li>• Testing and quality assurance</li>
                </ul>
              </div>

              <div className="bg-gray-50 p-8 rounded-lg">
                <h3 className="text-2xl font-semibold text-gray-900 mb-4">For Students</h3>
                <ul className="space-y-2 text-gray-600">
                  <li>• Feature suggestions and feedback</li>
                  <li>• Beta testing on campus</li>
                  <li>• Documentation and tutorials</li>
                  <li>• Community building and outreach</li>
                  <li>• Translation and localization</li>
                </ul>
              </div>
            </div>

            <div className="text-center">
              <a
                href="https://github.com/thesinghaman/studora"
                target="_blank"
                rel="noopener noreferrer"
                className="bg-blue-600 text-white px-8 py-3 rounded-lg text-lg font-semibold hover:bg-blue-700 transition-colors inline-flex items-center gap-2"
              >
                <Github size={20} />
                Contribute on GitHub
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-blue-600">
        <div className="container mx-auto px-6 text-center">
          <h2 className="text-4xl font-bold text-white mb-6">
            Be Part of the Campus Revolution
          </h2>
          <p className="text-xl text-blue-100 mb-8 max-w-2xl mx-auto">
            Follow our development journey and be among the first to experience Studora when it launches.
          </p>
          <a
            href="https://github.com/thesinghaman/studora"
            target="_blank"
            rel="noopener noreferrer"
            className="bg-white text-blue-600 px-8 py-4 rounded-lg text-lg font-semibold hover:bg-gray-100 transition-colors inline-flex items-center gap-2"
          >
            <Github size={20} />
            Star on GitHub
          </a>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="container mx-auto px-6">
          <div className="grid md:grid-cols-3 gap-8">
            <div>
              <div className="text-2xl font-bold mb-4">Studora</div>
              <p className="text-gray-400 mb-4">
                An innovative open-source campus marketplace and community platform.
              </p>
              <p className="text-sm text-gray-500">
                Currently in development - Mobile app coming soon!
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Project</h4>
              <ul className="space-y-2 text-gray-400">
                <li><Link href="#about" className="hover:text-white transition-colors">About</Link></li>
                <li><Link href="#roadmap" className="hover:text-white transition-colors">Roadmap</Link></li>
                <li><Link href="#contribute" className="hover:text-white transition-colors">Contribute</Link></li>
                <li><a href="https://github.com/thesinghaman/studora" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">GitHub</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Contact</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="https://github.com/thesinghaman/studora/issues" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Report Issues</a></li>
                <li><a href="https://github.com/thesinghaman/studora/discussions" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Discussions</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-gray-400">
            <p>&copy; 2025 Studora. Open source project. MIT License.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
