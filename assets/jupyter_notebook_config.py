import os

c.NotebookApp.ip='0.0.0.0'
c.NotebookApp.port = int(os.getenv('PORT', 8888))
c.NotebookApp.open_browser = False
c.MultiKernelManager.default_kernel_name = 'python3'
c.NotebookApp.notebook_dir = './'
c.Application.log_level = 0
c.NotebookApp.allow_root = True
c.NotebookApp.terminado_settings = { 'shell_command': ['/bin/bash', '-i'] }

# Authentication TOKEN
# WARNING : Leaving  empty Token could be insecure. ONLY use on private Network/Local Workstation
c.NotebookApp.token = ''

