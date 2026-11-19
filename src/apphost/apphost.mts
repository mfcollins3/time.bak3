// Copyright 2026 Michael F. Collins, III
// Licensed under the Naked Time license. See LICENSE.md for details.

import { createBuilder } from './.aspire/modules/aspire.mjs';

const builder = await createBuilder();

// Add your resources here, for example:
// const redis = await builder.addContainer("cache", "redis:latest");
// const postgres = await builder.addPostgres("db");

await builder.build().run();