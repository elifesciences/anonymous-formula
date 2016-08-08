builder-project-aws-credentials:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user }}/.aws/credentials
        - source: salt://anonymous/config/home-deploy-user-.aws-credentials
        - template: jinja
        - user: {{ pillar.elife.deploy_user }}
        - group: {{ pillar.elife.deploy_user }}
        - makedirs: True

builder-project:
    git.latest:
        - name: ssh://git@github.com/elifesciences/builder.git
        - rev: master
        - force: True
        - force_fetch: True
        - force_reset: True
        - target: /srv/builder

    file.directory:
        - name: /srv/builder
        - user: {{ pillar.elife.deploy_user }}
        - group: {{ pillar.elife.deploy_user }}
        - recurse:
            - user
            - group
        - require:
            - git: builder-project

    cmd.run:
        - name: ./update.sh --exclude virtualbox vagrant
        - cwd: /srv/builder
        - user: {{ pillar.elife.deploy_user }}
        - require:
            - file: builder-project
            - file: builder-project-aws-credentials

builder-settings:
    file.managed:
        - name: /srv/builder/settings.yml
        - source: salt://anonymous/config/srv-builder-settings.yml
        - user: {{ pillar.elife.deploy_user }}
        - group: {{ pillar.elife.deploy_user }}
        - require:
            - cmd: builder-project
