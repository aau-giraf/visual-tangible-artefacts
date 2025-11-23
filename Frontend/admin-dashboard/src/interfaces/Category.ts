import { ArtefactGetDTO } from './Artefact';

export interface CategoryGetDTO {
  categoryId: string;
  categoryIndex?: number;
  name?: string;
  imageUrl?: string;
  usageCount: number;
  lastUsedDate?: Date;
  artefacts: ArtefactGetDTO[];
}
