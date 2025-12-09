export interface UserLoginDTO {
  username: string;
  password?: string;
}

export interface UserLoginResponseDTO {
  token: string;
  userId: string;
}
