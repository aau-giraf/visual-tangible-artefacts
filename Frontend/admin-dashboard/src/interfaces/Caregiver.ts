import { UserGetDTO } from "./User";

export interface Caregiver extends UserGetDTO {
    children: UserGetDTO[];
}
