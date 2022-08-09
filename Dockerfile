FROM fstlx/qt5:ubuntu18 AS build

ARG SKYSCRAPER_RELEASE
RUN if [ -z ${SKYSCRAPER_RELEASE} ]; then echo "you MUST specify a SKYSCRAPER_RELEASE" 1>&2; exit 1; fi

RUN wget -N https://github.com/muldjord/skyscraper/archive/${SKYSCRAPER_RELEASE}.tar.gz && \
    tar xvzf ${SKYSCRAPER_RELEASE}.tar.gz --strip-components 1 --overwrite && \
    rm ${SKYSCRAPER_RELEASE}.tar.gz && \ 
    qmake && \
    make -j$(nproc) && \
    make install

FROM fstlx/qt5:ubuntu18

COPY --from=build /usr/local /usr/local

