const String schemaTemplate = r'''
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-dart-client"
}

datasource db {
  provider = "{datasource-provider}"
  url      = env("DATABASE_URL")
}
''';
