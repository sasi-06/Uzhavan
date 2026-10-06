import { Controller, Get, Post, Query, Body, Param } from '@nestjs/common';
import { SchemesService } from './schemes.service';

@Controller('schemes')
export class SchemesController {
  constructor(private readonly schemesService: SchemesService) {}

  /**
   * GET /api/v1/schemes
   * Optional query params:
   * ?role=FARMER or MACHINE_OWNER
   * ?lang=ta or te or hi or en
   * ?category=MACHINERY_SUBSIDY | DIRECT_BENEFIT | etc.
   */
  @Get()
  async getSchemes(
    @Query('role') role?: string,
    @Query('lang') lang?: string,
    @Query('category') category?: string,
  ) {
    return this.schemesService.getSchemes(role, lang || 'ta', category);
  }

  /**
   * GET /api/v1/schemes/:id
   */
  @Get(':id')
  async getSchemeById(@Param('id') id: string, @Query('lang') lang?: string) {
    return this.schemesService.getSchemeById(id, lang || 'ta');
  }

  /**
   * POST /api/v1/schemes/seed
   * Automatically populates Firestore collection 'schemes' with all schemes.
   */
  @Post('seed')
  async seedSchemes() {
    return this.schemesService.seedSchemes();
  }

  /**
   * POST /api/v1/schemes/sync-data-gov
   * Body: { apiKey: string, resourceId: string, state?: string }
   */
  @Post('sync-data-gov')
  async syncFromDataGov(
    @Body() body: { apiKey?: string; resourceId?: string; state?: string },
  ) {
    const key = body.apiKey || process.env.DATA_GOV_IN_API_KEY;
    const resId =
      body.resourceId ||
      process.env.DATA_GOV_IN_RESOURCE_ID ||
      '9ef84268-d588-465a-a308-a864a43d0070';

    if (!key) {
      return {
        error: 'API key is required. Please pass apiKey in the request body or configure DATA_GOV_IN_API_KEY in .env',
      };
    }

    return this.schemesService.syncFromDataGov(key, resId, body.state || 'Tamil Nadu');
  }
}
