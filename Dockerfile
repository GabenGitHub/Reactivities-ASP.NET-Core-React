ARG DOTNETVERSION=3.1-alpine
ARG NODEVERSION=16-alpine

FROM mcr.microsoft.com/dotnet/sdk:${DOTNETVERSION} AS asp_build
WORKDIR /app

# copy csproj and restore as distinct layers
COPY API/API.csproj ./API/
COPY Application/Application.csproj ./Application/
COPY Domain/Domain.csproj ./Domain/
COPY Persistence/Persistence.csproj ./Persistence/
RUN dotnet restore API/API.csproj

# copy everything else and build app
COPY . .

WORKDIR /app
RUN dotnet publish -c release API/API.csproj -o /build

# React build
FROM node:${NODEVERSION} AS node_build

#set working directory
RUN mkdir -p /app/client-app
WORKDIR /app/client-app

#add `/app/node_modules/.bin` to $PATH
ENV PATH /app/client-app/node_modules/.bin:$PATH

#install and cache app dependencies
COPY client-app/package.json /app/client-app/package.json
RUN npm install

#add app
COPY --from=asp_build /app/client-app/. /app/client-app

RUN npm run build
# End React build

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:${DOTNETVERSION} AS runtime

WORKDIR /app
COPY --from=asp_build /build .

RUN mkdir -p /wwwroot
COPY --from=node_build /app/client-app/build/. /app/wwwroot/
EXPOSE 80
ENTRYPOINT ["dotnet", "API.dll"]