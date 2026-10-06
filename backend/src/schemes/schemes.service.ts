import { Injectable, Logger } from '@nestjs/common';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { MASTER_SCHEMES, SchemeItem } from './schemes.data';

@Injectable()
export class SchemesService {
  private readonly logger = new Logger(SchemesService.name);

  private get db() {
    return getFirestore();
  }

  /**
   * Seeds all master government schemes directly into Firestore.
   */
  async seedSchemes(): Promise<{ count: number; message: string }> {
    const batch = this.db.batch();
    const collectionRef = this.db.collection('schemes');

    for (const scheme of MASTER_SCHEMES) {
      const docRef = collectionRef.doc(scheme.id);
      batch.set(
        docRef,
        {
          ...scheme,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    await batch.commit();
    this.logger.log(`Seeded ${MASTER_SCHEMES.length} schemes into Firestore collection 'schemes'`);
    return {
      count: MASTER_SCHEMES.length,
      message: `Successfully seeded ${MASTER_SCHEMES.length} government schemes to Firestore!`,
    };
  }

  /**
   * Retrieves schemes from Firestore with optional filtering.
   */
  async getSchemes(role?: string, lang: string = 'ta', category?: string) {
    let query: FirebaseFirestore.Query = this.db.collection('schemes').where('isActive', '==', true);

    if (role && role.toUpperCase() !== 'ALL') {
      const normalizedRole = role.toUpperCase();
      // Schemes for FARMER, MACHINE_OWNER, or BOTH
      query = query.where('targetRole', 'in', [normalizedRole, 'BOTH']);
    }

    if (category) {
      query = query.where('category', '==', category.toUpperCase());
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      // Fallback to local master data if Firestore hasn't been seeded yet
      return this.filterMasterLocally(role, lang, category);
    }

    return snapshot.docs.map((doc) => {
      const data = doc.data() as SchemeItem;
      return this.formatForLanguage(data, lang);
    });
  }

  /**
   * Get a single scheme with complete localized breakdown.
   */
  async getSchemeById(id: string, lang: string = 'ta') {
    const doc = await this.db.collection('schemes').doc(id).get();
    if (!doc.exists) {
      const found = MASTER_SCHEMES.find((s) => s.id === id);
      if (!found) return null;
      return this.formatForLanguage(found, lang);
    }

    const data = doc.data() as SchemeItem;
    return this.formatForLanguage(data, lang);
  }

  /**
   * Syncs live Mandi prices or agricultural data from data.gov.in using the API Key
   */
  async syncFromDataGov(apiKey: string, resourceId: string, stateName: string = 'Tamil Nadu') {
    try {
      const url = `https://api.data.gov.in/resource/${resourceId}?api-key=${apiKey}&format=json&limit=50&filters[state]=${encodeURIComponent(stateName)}`;
      this.logger.log(`Fetching from data.gov.in: ${url}`);

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Data.gov.in responded with status ${response.status}: ${response.statusText}`);
      }

      const json = await response.json();
      const records = json.records || [];

      // Store fetched records into Firestore under 'market_prices' collection
      if (records.length > 0) {
        const batch = this.db.batch();
        const marketCol = this.db.collection('market_prices');

        for (const item of records) {
          const docId = `${item.state || 'IN'}_${item.district || ''}_${item.market || ''}_${item.commodity || ''}`
            .replace(/[^a-zA-Z0-9_]/g, '_')
            .toLowerCase();

          const docRef = marketCol.doc(docId);
          batch.set(
            docRef,
            {
              ...item,
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        }

        await batch.commit();
        this.logger.log(`Stored ${records.length} market price records into Firestore!`);
      }

      return {
        success: true,
        count: records.length,
        records: records.slice(0, 10), // Return sample records
      };
    } catch (err: any) {
      this.logger.error(`Failed to sync from data.gov.in: ${err.message}`);
      throw err;
    }
  }

  private filterMasterLocally(role?: string, lang: string = 'ta', category?: string) {
    let list = MASTER_SCHEMES;
    if (role && role.toUpperCase() !== 'ALL') {
      const norm = role.toUpperCase();
      list = list.filter((s) => s.targetRole === norm || s.targetRole === 'BOTH');
    }
    if (category) {
      list = list.filter((s) => s.category === category.toUpperCase());
    }
    return list.map((s) => this.formatForLanguage(s, lang));
  }

  private formatForLanguage(scheme: SchemeItem, lang: string) {
    const l = (['ta', 'te', 'hi', 'en'].includes(lang) ? lang : 'en') as 'ta' | 'te' | 'hi' | 'en';

    return {
      id: scheme.id,
      targetRole: scheme.targetRole,
      category: scheme.category,
      subsidyBadge: scheme.subsidyBadge[l] || scheme.subsidyBadge.en,
      title: scheme.title[l] || scheme.title.en,
      shortDesc: scheme.shortDesc[l] || scheme.shortDesc.en,
      overview: scheme.overview[l] || scheme.overview.en,
      benefits: scheme.benefits[l] || scheme.benefits.en,
      eligibility: scheme.eligibility[l] || scheme.eligibility.en,
      documentsRequired: scheme.documentsRequired[l] || scheme.documentsRequired.en,
      howToApply: scheme.howToApply[l] || scheme.howToApply.en,
      applyUrl: scheme.applyUrl,
      helpline: scheme.helpline,
      state: scheme.state,
      rawTranslations: {
        title: scheme.title,
        shortDesc: scheme.shortDesc,
        subsidyBadge: scheme.subsidyBadge,
      },
    };
  }
}
