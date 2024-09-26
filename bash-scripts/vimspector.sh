#!/bin/bash

touch .vimspector.json

cat <<EOF > .vimspector.json
{
  "configurations": {
    "Python: Launch": {
      "adapter": "debugpy",
      "filetypes": [ "python" ],
      "configuration": {
        "name": "Python: Launch",
        "type": "python",
        "request": "launch",
        "cwd": "\${workspaceRoot}",
        "python": "./venv/bin/python",
        "stopOnEntry": true,
        "console": "externalTerminal",
        "debugOptions": [],
        "program": "\${file}"
      }
    }
  }
}

EOF

