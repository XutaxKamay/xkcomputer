import secrets

def generate_tea_key():
    key_size_bytes = 16
    
    key = secrets.token_bytes(key_size_bytes)
    
    return key

tea_key = generate_tea_key()

print(tea_key.hex())

tea_key = [f"x\"{format(int.from_bytes(tea_key[i:i+4], byteorder='big'), '08x')}\"" for i in range(0, 16, 4)] 

print("constant TEA_KEY: TEA_KEY_TYPE := (", ', '.join(tea_key) , ");")
