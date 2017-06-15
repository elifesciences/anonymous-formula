ssh-credentials-private-key:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/.ssh/id_rsa
        - source: salt://anonymous/config/home-deploy-user-.ssh-id_rsa
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - mode: 400
        - makedirs: True

ssh-credentials-public-key:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/.ssh/id_rsa.pub
        - source: salt://anonymous/config/home-deploy-user-.ssh-id_rsa.pub
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - mode: 444
        - makedirs: True

git-config:
    cmd.run:
        - name: |
            git config --global user.name "Anonymous"
            git config --global user.email "anonymous@elifesciences.org"
        - user: {{ pillar.elife.deploy_user.username }}

github-token:
    cmd.run:
        - name: echo {{ pillar.anonymous.github.token }} > /home/{{ pillar.elife.deploy_user.username }}/github_token
        - user: {{ pillar.elife.deploy_user.username }}

builder-private:
    git.latest:
        - name: git@github.com:elife-anonymous-user/builder-private.git
        - identity: salt://anonymous/config/home-deploy-user-.ssh-id_rsa
        - force: True
        - force_fetch: True
        - force_reset: True
        - target: /srv/builder-private

    file.directory:
        - name: /srv/builder-private
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - git: builder-private

builder-project-aws-credentials:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/.aws/credentials
        - source: salt://anonymous/config/home-deploy-user-.aws-credentials
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - makedirs: True

builder-project-dependencies:
    pkg.installed:
        - pkgs:
            - make


builder-project:
    git.latest:
        - name: git@github.com:elifesciences/builder.git
        - identity: salt://anonymous/config/home-deploy-user-.ssh-id_rsa
        - rev: master
        - force: True
        - force_fetch: True
        - force_reset: True
        - target: /srv/builder
        - require:
            - builder-project-dependencies

    file.directory:
        - name: /srv/builder
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - git: builder-project

    cmd.run:
        - name: ./update.sh --exclude virtualbox vagrant ssh-agent
        - cwd: /srv/builder
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - file: builder-project
            - file: builder-project-aws-credentials

builder-settings:
    file.managed:
        - name: /srv/builder/settings.yml
        - source: salt://anonymous/config/srv-builder-settings.yml
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require:
            - cmd: builder-project
