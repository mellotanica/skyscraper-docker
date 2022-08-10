FROM fstlx/qt5:ubuntu18 AS base

RUN apt-get -y install inotify-tools


FROM fstlx/qt5:ubuntu18 AS build

ARG SKYSCRAPER_RELEASE
RUN if [ -z ${SKYSCRAPER_RELEASE} ]; then echo "you MUST specify a SKYSCRAPER_RELEASE" 1>&2; exit 1; fi

RUN wget -N https://github.com/muldjord/skyscraper/archive/${SKYSCRAPER_RELEASE}.tar.gz
RUN tar xvzf ${SKYSCRAPER_RELEASE}.tar.gz --strip-components 1 --overwrite
RUN rm ${SKYSCRAPER_RELEASE}.tar.gz
RUN qmake
RUN make -j$(nproc)
RUN make install

RUN git clone https://github.com/ncopa/su-exec
RUN make -C su-exec
RUN cp su-exec/su-exec /usr/local/bin


FROM base

ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["sh", "/scrape.sh"]
WORKDIR /
VOLUME /cache

COPY --from=build /usr/local /usr/local

COPY entrypoint.sh /
COPY scrape.sh /
RUN chmod +x /entrypoint.sh /scrape.sh
