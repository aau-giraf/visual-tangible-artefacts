import { CategoryGetDTO } from './Category';

export enum UserRole {
  Child = 0,
  Caregiver = 1,
  Admin = 2
}

export interface UserGetDTO {
  id: string;
  name?: string;
  username: string;
  role: UserRole;
  categories?: CategoryGetDTO[];
}

export interface UserPostDTO {
  name?: string;
  password?: string;
  username: string;
  role: UserRole;
}

export interface UserSignupDTO {
  username: string;
  password?: string;
  name: string;
  role: UserRole;
}
