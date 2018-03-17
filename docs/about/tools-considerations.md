# Tools considerations

Being just "glue", CWT does not attempt to compete with existing tools (or workflows). Here's a list of articles, open-source projects and services I try to keep in mind when evaluating what belongs in CWT - and what does not.

## Precepts (modules, components, includes)

- [Atomic Design](http://atomicdesign.bradfrost.com/table-of-contents/) #high-level #theory
- [Distilling How We Think About Design Systems](https://publication.design.systems/distilling-how-we-think-about-design-systems-b26432eefef9) #high-level #theory
- [File organisation](http://ecss.io/chapter5.html) #architecture #orientation #dx

## Workflows

- [A Successful One-Click Deployment in Drupal 8](https://www.lullabot.com/articles/a-successful-drupal-8-deployment) #example
- [Just enough Ansible for Drupal](https://lakshminp.com/just-enough-ansible-drupal) #example
- [phenomic/phenomic](https://github.com/phenomic/phenomic) #static #compilation
- [mavoweb/mavo](https://github.com/mavoweb/mavo) #static #minimal
- [travis-ci/dpl](https://github.com/travis-ci/dpl) #deploy #ci
- [gitlab.com/help/topics/autodevops](https://gitlab.com/help/topics/autodevops/index.md) #ci

## Stacks

- [lando/lando](https://github.com/lando/lando) #local #stack #extensions #docker-compose
- [wodby/docker4drupal](https://github.com/wodby/docker4drupal) #local #stack #extensions #docker-compose
- [geerlingguy/drupal-vm](https://github.com/geerlingguy/drupal-vm/tree/master/provisioning) #local #stack #extensions #ansible
- [dokku/dokku](https://github.com/dokku/dokku) #PaaS #cli #heroku-buildpacks
- [Haufe-Lexware/wicked.haufe.io](https://github.com/Haufe-Lexware/wicked.haufe.io) #PaaS #modular #microservices

## Other tools

- [WebReflection/hyperHTML](https://github.com/WebReflection/hyperHTML) #components #compilation
- [inuitcss/inuitcss](https://github.com/inuitcss/inuitcss) #css #compilation
- [asciidoctor/docker-asciidoctor](https://github.com/asciidoctor/docker-asciidoctor) #print #components #container
- [zeit/next.js](https://github.com/zeit/next.js) #framework #js
- [serverless/serverless](https://github.com/serverless/serverless) #PaaS #cli #framework #nodejs
- [mikeal/r2](https://github.com/mikeal/r2) #backend #js #research
- [contentacms/contenta_jsonapi](https://github.com/contentacms/contenta_jsonapi) #framework #backend
- [apollographql/apollo-client](https://github.com/apollographql/apollo-client) #api #interface #graph #database
- [arangodb/arangodb](https://github.com/arangodb/arangodb) #graph #database
- [phoenixframework/phoenix](https://github.com/phoenixframework/phoenix) #framework #backend
- [IEMLdev/ieml](https://github.com/IEMLdev/ieml) #syntax #research #ai
