require 'configatron'

c = configatron.app
c.path.root                   = File.expand_path('..', __dir__)
c.path.base.projects          = 'config/projects'
c.path.templates              = c.path.root + '/' + 'templates'
c.path.base.users             = 'config/users'
c.path.projects               = c.path.root + '/' + c.path.base.projects
c.path.users                  = c.path.root + '/' + c.path.base.users
c.path.src                    = c.path.root + '/src'
