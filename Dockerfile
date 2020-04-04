FROM registry.access.redhat.com/ubi8/ruby-25

ENV VERSION 0.0.1

LABEL io.k8s.description="metals-example" \
  io.k8s.display-name="metals-example v${VERSION}" \
  io.openshift.tags="test,qa" \
  name="metals-example" \
  architecture="x86_64" \
  maintainer="github.com/FreedomBen"

COPY . /app

WORKDIR /app
USER root
RUN bundle install --local

USER default
EXPOSE 8080
CMD /app/app.rb
