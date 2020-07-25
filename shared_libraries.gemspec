Gem::Specification.new do |s|
  s.name         = 'shared_libraries'
  s.version      = '0.0.1'
  s.date         = '2019-01-16'
  s.summary      = "Shared libraries"
  s.description  = "Shared libraries for buy nsw services"
  s.authors      = ["Arman"]
  s.email        = 'arman.sarrafi@customerservice.nsw.gov.au'
  s.files        = Dir.glob('lib/**/*.rb')
  s.require_path = ['lib']
  s.license       = 'MIT'

  s.add_dependency "activeresource", "~> 5.1.0"
  s.add_dependency "jwt"
end
