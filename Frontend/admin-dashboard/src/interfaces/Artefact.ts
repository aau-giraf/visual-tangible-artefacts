export interface ArtefactGetDTO {
  artefactId: string;
  artefactIndex: number;
  userId: string;
  categoryId?: string;
  name?: string;
  nameShown?: boolean;
  imageUrl?: string;
  soundUrl?: string;
}
